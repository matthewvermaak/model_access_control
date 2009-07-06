class MethodExists < Exception; end

# == Overview
#  - This class is used to configure the [M]odel [A]ccess [C]ontrol
#    for a particular application.
#
# == Example Usage
#
#  Mac.configure do |config|
#    config.principal Employee do
#      ...
#    end
#
#    config.intercept Vendor, [:update, :create] do
#      ... 
#      (self in this context refers to the Vendor instance)
#    end
#   
#    config.secured_filter [Vendor] do
#      ...
#      {:conditions => ..., :joins => ...}
#    end
#  end
#
class Mac
  AR_CALLBACKS = [:update, :create, :save, :destroy]
  SCOPE_NAME = :secured

#---------------------------------------------------------------------#
#                         Open the Config                             #
#---------------------------------------------------------------------#
#  Mac.configure do |config|
#  end 

  def self.configure
    begin
      yield self
    rescue ActiveRecord::StatementInvalid; end
  end

#---------------------------------------------------------------------#
#                           API methods                               #
#---------------------------------------------------------------------#
# config.principal, config.intercept, config.secured_filter
  
  ##
  # Set the principals for use with Mac.
  # Injects a class attribute : current : into each principal.
  # The block of code is injected into a before_filter in application_controller.
  # It is expected to contain the logic necessary to set the current for that principal.
  #
  def self.principal(principal, &block)
    inject_current_into_principal!(principal)
    inject_block_into_application_controller!(principal, &block)
  end
  
  ##
  # Define the block of code to be executed before events
  # affecting a target model.
  #
  # :Expects:
  #   - target    => Target model class to be injected.
  #   - callbacks => An array of the callbacks to intercept.
  #                  This includes not only the AR callbacks
  #                  but any instance method.
  #                  
  #   - &block    => The block of code to execute. 
  #
  def self.intercept(target, callbacks, &block)
    callbacks.each do |callback|
      # Check for existing chains...
      unless already_has_mac_callback?(target, callback)
        # Inject chain logic, if not already present
        establish_chain(target, callback)
      end
      # Inject necessary method
      write_method(target, callback, &block)  
    end
  end
   
  ##
  # Define the block of code to be inserted as the
  # named_scope :secured body.
  # 
  # :Expects:
  #  - targets    => Array of target Model classes
  #  - &block     => The block of code to execute as the named scope.
  #
  def self.secured_filter(targets, &block)
    targets.each do |target|
      inject_named_scope_into_target!(target, &block)
    end
  end

private
#---------------------------------------------------------------------#
#                           Helper methods                            #
#---------------------------------------------------------------------#

  ##
  # Adds a class attribute called current to the principal class.
  #
  def self.inject_current_into_principal!(principal)
    # Protect against double injection.
    unless principal.respond_to? :current
      principal.class_eval %Q{
        def self.current
          Thread.current["#{principal}"]
        end
   
        def self.current=(current_principal)
          Thread.current["#{principal}"] = current_principal
        end
      }
    end
  end

  ##
  # Create the named_scope for the target class.
  #
  def self.inject_named_scope_into_target!(target, &block)
    if named_scope_exists_for?(target)
      # raise MethodExists.new(":#{SCOPE_NAME}: named scope already exists in #{target.class_name}.")
    else
      write_scope(target, &block)
    end
  end

  ##
  # Write the named_scope of SCOPE_NAME (:secured)
  #
  def self.write_scope(target, &block)  
    target.send(:named_scope, SCOPE_NAME, block)
  end

  ##
  # Check for existence of the :secured named scope.
  #
  def self.named_scope_exists_for?(target)
    target.scopes.keys.include? SCOPE_NAME
  end
   
  ##
  # Adds the block of code as a before_filter to application_controller.
  # Expected to set the principal.current
  #
  def self.inject_block_into_application_controller!(principal, &block)
    method_name = "mac_set_#{principal.class_name.underscore}"
    # Protect against double injection.
    unless ApplicationController.instance_methods.include? method_name
      ApplicationController.send(:define_method, method_name, &block)
      ApplicationController.send(:before_filter, method_name)
    end
  end

  ##
  # Delegates to AR or Custom chain creation
  #
  def self.establish_chain(target, callback)
    if is_ar_callback?(callback)
      establish_chain_for_ar_callback(target, callback)
    else
      if is_class_method? callback
        establish_chain_for_custom_class_callback(target, callback)
      else
        establish_chain_for_custom_callback(target, callback)
      end
    end
  end 

  ##
  # Adds a mac_before_<method_name> to the before_:callback chain
  #
  def self.establish_chain_for_ar_callback(target, callback)
    target.send("before_#{callback}", "mac_before_#{callback}", {:mac_callback => true})
  end

  ##
  # Wraps the custom method in a alias_method_chain where in
  # the mac_before_<method_name> is used as a gatekeeper
  # on the custom method.
  #
  def self.establish_chain_for_custom_callback(target, callback)
    target.class_eval %Q{
       def #{callback.to_s}_with_mac_callback(*args)
         if mac_before_#{callback.to_s}(*args)
           #{callback.to_s}_without_mac_callback(*args)
         end
       end
    }
    target.send(:alias_method_chain, callback, :mac_callback)
  end

  ##
  # Wrap the custom class method in an alias_method_chain
  #
  def self.establish_chain_for_custom_class_callback(target, callback)
    callback_without_self = remove_self(callback)
    target.class_eval %Q{
       def #{callback.to_s}_with_mac_callback(*args)
         if self.mac_before_#{callback_without_self.to_s}(*args)
           #{callback.to_s}_without_mac_callback(*args)
         end
       end

       (class << self; self; end).module_eval do
         alias_method_chain :#{callback_without_self}, :mac_callback
       end
    }
  end
 
  ##
  # Defines the injected code as an instance method into the class.
  #
  def self.write_method(target, callback, &block)
    if is_class_method? callback
      callback = remove_self(callback) 
      (target.class_eval "class << self; self; end").send(:define_method, "mac_before_#{callback}", &block)
    else
      target.send(:define_method, "mac_before_#{callback}", &block)
    end
  end

  ##
  # Delegates to AR or Custom callback checkers
  # 
  def self.already_has_mac_callback?(target, callback)
    if is_ar_callback?(callback)
      self.contained_in_ar_callbacks?(target, callback)
    else
      if is_class_method?(callback) 
        self.contained_in_custom_class_callbacks?(target, callback)
      else
        self.contained_in_custom_callbacks?(target, callback)
      end
    end
  end

  ##
  # Checks for an instance method already defined of the type: mac_before_<method_name>
  # Assumed that this means there is already a callback structure defined.
  #
  def self.contained_in_custom_callbacks?(target, callback)
    if target.instance_methods.include? "mac_before_#{callback}"
      return true
    end 
    return false
  end

  ## 
  # Checks for a singleton method already defined of the type: mac_before_<method_name>
  #
  def self.contained_in_custom_class_callbacks?(target, callback)
    callback = remove_self(callback)
    if target.singleton_methods.include? "mac_before_#{callback}"
      return true
    end
    return false
  end

  ##
  # Checks the callback chain of the model. Particularily looking for callbacks of the type
  # confirmed by Mac.is_ar_callback? with the additional flag of :mac_callback set to true.
  # This requirement is used instead of name checking, just incase the names happened to 
  # overlap. (mac_before_update)
  #
  def self.contained_in_ar_callbacks?(target, callback)
    target.send("before_#{callback.to_s}_callback_chain").each do |potential_callback|
      if potential_callback.options.include? :mac_callback and potential_callback.options[:mac_callback]
        return true
      end
    end
    return false
  end
  
  ##
  # Checks for :update, :create, :save, :destroy
  #
  def self.is_ar_callback?(callback)
    AR_CALLBACKS.include? callback
  end  

  ##
  # Returns true if a class method is being intercepted
  #
  def self.is_class_method?(callback)
    if callback =~ /^self\./
      return true
    end
    return false
  end
  
  ##
  # Strips 'self.' from callback name
  #
  def self.remove_self(callback)
    return callback[5..-1]
  end
end
