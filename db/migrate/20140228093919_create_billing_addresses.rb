class CreateBillingAddresses < ActiveRecord::Migration
  def change
    create_table :billing_addresses do |t|
      t.string :house_no
      t.string :street_address
      t.string :city
      t.string :state
      t.string :zip_code
      t.integer :user_id
      t.boolean :is_active

      t.timestamps
    end
  end
end
