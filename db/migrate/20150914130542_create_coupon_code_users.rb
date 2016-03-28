class CreateCouponCodeUsers < ActiveRecord::Migration
  def change
    create_table :coupon_code_users do |t|
      t.integer :user_id
      t.integer :coupon_code_id
      t.integer :job_id

      t.timestamps
    end
  end
end
