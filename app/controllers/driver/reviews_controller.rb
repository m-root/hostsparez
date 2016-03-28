class Driver::ReviewsController < Driver::DriverController

  before_filter :authenticate_user!

  def index
    @driver_reviews = current_user.driver_reviews
    @driver_rating_whole, @driver_rating_part = current_user.driver_rating
  end


  def show

  end

end
