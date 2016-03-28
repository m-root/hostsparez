class CreateCustomerSettings < ActiveRecord::Migration
  def change
    create_table :customer_settings do |t|
      t.integer :user_id
      t.boolean :is_push_notification, :default => true
      t.boolean :is_email_notification, :default => true
      t.boolean :is_text_notification ,:default => true

      t.timestamps
    end
  end
end
