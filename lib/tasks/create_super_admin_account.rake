require 'rubygems'
require File.join(File.dirname(__FILE__), "..", "..", "config", "environment")
task :create_super_admin_account do
  brain_customer = Braintree::Customer.create(
      :first_name => "super",
      :last_name => "admin",
      :email => "super_admin@ziply.com"
  )
  User.where(:email => "super_admin@ziply.com").first.update_attribute("customer_id", brain_customer.customer.id)
end

