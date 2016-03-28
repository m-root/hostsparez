class CreatePaymentMethods < ActiveRecord::Migration
  def change
    create_table :payment_methods do |t|
      t.string :holder_name
      t.integer :month
      t.integer :year
      t.integer :cvv
      t.string :card_number
      t.integer :user_id
      t.string :nick_name
      t.string :token
      t.boolean :is_active

      t.timestamps
    end
  end
end
