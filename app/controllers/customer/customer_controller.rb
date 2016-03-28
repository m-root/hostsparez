class Customer::CustomerController < ApplicationController

  before_filter do
    if current_user
      redirect_to root_url unless current_user.customer?
    end
  end

end
