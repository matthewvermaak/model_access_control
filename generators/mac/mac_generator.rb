class MacGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.file 'initializer.rb', "config/initializers/mac.rb"
    end
  end

end
