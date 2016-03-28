class OurDriversController < ApplicationController

  def index
    @drivers = User.drivers.where(:is_disabled => false)
  end

end