class AddDriverAmountAndZiplyRevenueToTransactionHistories < ActiveRecord::Migration
  def change
    add_column :transaction_histories, :driver_amount, :float
    add_column :transaction_histories, :ziply_revenue, :float
    add_column :transaction_histories, :brain_tree_fee, :float
    add_column :transaction_histories, :ziply_gross_revenue, :float
  end
end
