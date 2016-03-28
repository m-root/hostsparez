class AddPaymentMethodIdToBillingAddress < ActiveRecord::Migration
  def change
    add_column :billing_addresses, :payment_method_id, :integer
  end
end
