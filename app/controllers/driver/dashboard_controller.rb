class Driver::DashboardController < Driver::DriverController
  layout "driver"
  before_filter :authenticate_user!

  def index
    redirect_to driver_jobs_path
  end

end
