class AddIsDeletedToPaymentMethods < ActiveRecord::Migration
  def change
    add_column :payment_methods, :is_deleted, :boolean, :default => false
  end
end
