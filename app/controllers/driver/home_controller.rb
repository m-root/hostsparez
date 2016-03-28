class Driver::HomeController < Driver::DriverController

  def index
    redirect_to driver_dashboard_index_path
  end

end
