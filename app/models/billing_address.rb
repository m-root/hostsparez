class BillingAddress < ActiveRecord::Base
  attr_accessor :terms
  attr_accessible  :street_address, :city, :state, :zip_code, :user_id, :payment_method_id,:house_no
  validates_presence_of :street_address, :city, :state, :zip_code, :user_id
  validates_acceptance_of :terms
end
