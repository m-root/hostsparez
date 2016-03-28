class AddPaymentMethodIdToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :payment_method_id, :integer
    add_column :jobs, :billing_address_id, :integer
  end
end
