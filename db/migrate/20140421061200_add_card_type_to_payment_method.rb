class AddCardTypeToPaymentMethod < ActiveRecord::Migration
  def change
    add_column :payment_methods, :card_type, :string
  end
end
