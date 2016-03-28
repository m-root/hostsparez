class SuperAdmin::DashboardController < SuperAdmin::SuperAdminController
  #before_filter :set_partner, :except => [:create]
  layout "super_admin"

  def index
    @customers_count = User.customers.size
    @drivers_count = User.drivers.size
    @delivered_jobs_count = User.total_delivered_jobs.size
    @ziply_revenue = TransactionHistory.sum(:ziply_revenue) # => 4562
    @driver_revenue = TransactionHistory.sum(:driver_amount) # => 4562
  end

end
