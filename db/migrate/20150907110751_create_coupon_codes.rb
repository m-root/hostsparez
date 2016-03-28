class CreateCouponCodes < ActiveRecord::Migration
  def change
    create_table :coupon_codes do |t|
      t.string :code
      t.string :coupon_type
      t.float :coupon_value
      t.datetime :valid_from
      t.datetime :valid_to
      t.integer :user_id
      t.string :send_to_users
      t.integer :per_user, :default => 0
      t.integer :per_coupon, :default => 0
      t.string :status, :default => 'Open'
      t.integer :promotion_code_user_id
      t.string :promotion_code_user_type
      t.string :coupon_group
      t.boolean :is_send, :default => true

      t.timestamps
    end
  end
end
