require 'dispatcher' unless defined?(::Dispatcher)

Dispatcher.to_prepare do 
  if File.exists? "#{Rails.root}/config/initializers/mac.rb"
    load "#{Rails.root}/config/initializers/mac.rb"
  end
end
