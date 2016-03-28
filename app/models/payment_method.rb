class PaymentMethod < ActiveRecord::Base
  attr_accessible :holder_name, :month, :year, :cvv, :card_number, :user_id, :nick_name, :is_active, :token,
                  :card_type, :billing_address_attributes
  validates_presence_of :holder_name, :month, :year, :cvv, :card_number, :user_id
  belongs_to :user
  has_one :billing_address
  accepts_nested_attributes_for :billing_address, :allow_destroy => true

  def self.payment_method_json(u)
    u.payment_methods.map{|payment_method| {:id => payment_method.id, :card_type => payment_method.card_type, :card_number => mask_number(payment_method.token), :holder_name => payment_method.holder_name, :billing_address_id => payment_method.billing_address.blank? ? "" : payment_method.billing_address.id}}
  end

  def mask_number(token)
    @credit_card = BraintreeRails::CreditCard.find(token)
    return @credit_card.masked_number
  end

end
