class TransactionHistory < ActiveRecord::Base
  attr_accessible :transaction_id, :status, :transaction_type, :amount, :user_id, :payment_method_id,
                  :job_id, :billing_address_id, :driver_amount, :ziply_revenue, :brain_tree_fee, :ziply_gross_revenue, :escrow_status
  belongs_to :payment_method
  belongs_to :billing_address
  belongs_to :job
  belongs_to :user
end
