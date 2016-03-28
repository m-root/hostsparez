class CreateTransactionHistories < ActiveRecord::Migration
  def change
    create_table :transaction_histories do |t|
      t.string :transaction_id
      t.string :status
      t.string :transaction_type
      t.float :amount
      t.integer :user_id
      t.integer :payment_method_id
      t.integer :job_id
      t.integer :billing_address_id

      t.timestamps
    end
  end
end
