class Customer::LocationsController < Customer::CustomerController

  before_filter :authenticate_user!

  def del_pop_up
    location = Location.find_by_id(params[:id])
    @location = location if current_user.locations.include?(location)
    render :layout => false
  end

  def delete_location
    location = Location.find_by_id(params[:id])
    @location = location if current_user.locations.include?(location)
    if @location.destroy
      render :json => {:success => true, :html => render_to_string(:partial => 'customer/locations/location_del_success')}.to_json
    else
      render :json => {:success => false}
    end
  end

  def new
    @location = Location.new
    render :layout => false
  end

  def index
    @locations = current_user.locations
  end

  def check_unique_address(loc)
    location = Geocoder.search(loc.address)
    latitude = location[0].latitude
    longitude = location[0].longitude
    existing_location = Location.where(:user_id => self.current_user.id).select { |location| location.latitude == latitude and location.longitude == longitude }
    if existing_location.present?
      return false
    else
      return true
    end
  end


  def create
    @location = Location.new(params[:location])
    if @location.address.present?
      unless check_unique_address(@location)
        @message = "Location already exist"
        render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
        return
      end
    end
    if @location.save
      flash[:notice] = ":Location was successfully Added."
      render :json => {:success => true, :url => customer_locations_path}.to_json
    else
      @errors = @location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def edit
    location = Location.find_by_id(params[:id])
    @location = location if current_user.locations.include?(location)
    render :layout => false
  end

  def update
    location = Location.find_by_id(params[:id])
    @location = location if current_user.locations.include?(location)
    if @location.update_attributes(params[:location])
      flash[:notice] = "Location was successfully updated."
      render :json => {:success => true, :url => customer_locations_path}.to_json
    else
      @errors = @location.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def destroy
    location = Location.find_by_id(params[:id])
    @location = location if current_user.locations.include?(location)
    if @location.destroy
      flash[:notice] = "Location was successfully deleted."
      redirect_to :action => :index
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to :action => :index
    end
  end


end
