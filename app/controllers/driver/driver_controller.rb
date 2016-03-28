class Driver::DriverController < ApplicationController
  layout "driver"
  before_filter do
    if current_user
      redirect_to root_url unless current_user.driver?
    end
  end

end
