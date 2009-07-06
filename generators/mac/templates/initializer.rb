Mac.configure do |config|
  # --------------------------------------------------------------------- #
  #                            Prinicpals                                 #
  # --------------------------------------------------------------------- #
  # Declare the principals that can be used and the block of code to set it.
  # The block of code is injected into ApplicationController#before_filter's
  # config.principal Employee do 
  #   Employee.current = Employee.first
  # end

  # --------------------------------------------------------------------- #
  #                         Interception Points                           #
  # --------------------------------------------------------------------- #
  # Declare the interception points that you want to inject into the model base.
  # These interception points can be:
  #  - ActiveRecord Callbacks -> [:update, :create, :save, :destroy]
  #  - Any arbitrary instance method -> [:instance_method]
  #  - Any arbitrary class method -> ["self.some_class_method"]
  #  - Methods with arguments -> [:method_with_two_args] do |arg1, arg2|
  #
  # config.intercept Vendor, [:update] do 
  #   if Employee.current
  #     return true
  #   end
  #   return false
  # end
 
  # --------------------------------------------------------------------- #
  #                               Filters                                 #
  # --------------------------------------------------------------------- #
  # Declare the models to apply the secure filter to followed by the
  # block of code to execute to determine the conditions that constitute the
  # security. The block of code passed to secured_filter is turned into
  # the lambda parameter for the named_scope, so follow any restrictions
  # that apply there. Then use: Ticket.secured.find(...) to protect
  # DB reads.
  # config.secured_filter [Ticket] do
  #   {:conditions => ["account_id <= 10000"]}
  # end
end
