class Customer::HomeController < Customer::CustomerController

  def index
    redirect_to customer_dashboard_index_path
  end

end
