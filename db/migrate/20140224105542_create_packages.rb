class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
      t.string :name
      t.float :weight
      t.string :description
      t.float :amount
      t.integer :user_id
      t.float :basic_fee
      t.float :cost_per_mile
      t.float :min_fare

      t.timestamps
    end
  end
end
