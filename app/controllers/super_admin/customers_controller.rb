class SuperAdmin::CustomersController < SuperAdmin::SuperAdminController
  #before_filter :set_partner, :except => [:create]
  layout "super_admin"

  def index
    @customers = User.customers
    #@customers = @customers.paginate(:page => params[:page], :per_page => 5)
    #render :layout => false
  end

  def show
    @user = User.find_by_id(params[:id])
    @jobs = @user.customer_jobs.where("status != ?", "unavailable").order("id desc")
  end

  def search_customer
    if params[:term].present?
      like = "%".concat(params[:term].downcase.concat("%"))
      @customers = User.customers.where("lower(concat('first_name', 'last_name')) like ? or email like ?", like, like)
      @customers = @customers.paginate(:page => params[:page], :per_page => 5)
    else
      @customers = User.customers
      @customers = @customers.paginate(:page => params[:page], :per_page => 5)
    end
    render :partial => "super_admin/customers/list"
  end


  def new
    @user = User.new
    #render :layout => false
  end

  def create
    @user = User.new(params[:user])
    @user.roles << Role.find_by_name("customer")
    if @user.save and @user.clone_customer_setting(@user)
      flash[:notice] = "Driver was successfully Added."
      redirect_to super_admin_customers_path
      #render :json => {:success => "true", :url => super_admin_driver_path(:id => @user.id, :partner_id => @user.partner.id)}.to_json
    else
      render "new"
      #render :json => {:success => "false", :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def edit
    @user = User.find_by_id(params[:id])
    #render :layout => false
  end

  def upload_photo
    @user = User.find_by_id(params[:id])
    if @user.update_without_password(params[:user])
      flash[:notice] = "Driver was successfully updated."
      @user = User.send_reset_password_instructions(params[:user])
      #if successfully_sent?(@user)
      #  head :status => 200
      #else
      #  render :status => 422, :json => {:errors => @user.errors.full_messages}
      #end
      render :json => {:success => "true", :url => super_admin_drivers_path}.to_json

    else
      @errors = @user.errors
      render :json => {:success => "false", :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end


  def update
    @user = User.find_by_id(params[:id])
    successfully_updated = if needs_password?(@user, params)
                             @user.update(params[:user])
                           else
                             params[:user].delete(:password)
                             @user.update_without_password(params[:user])
                           end
    if successfully_updated
      flash[:notice] = "Customer was successfully updated."
      redirect_to super_admin_customers_path
    else
      render "edit"
    end
    #if @user.update(params[:user])
    #  flash[:notice] = "Driver was successfully updated."
    #  @user = User.send_reset_password_instructions(params[:user])
    #  #if successfully_sent?(@user)
    #  #  head :status => 200
    #  #else
    #  #  render :status => 422, :json => {:errors => @user.errors.full_messages}
    #  #end
    #  #render :json => {:success => "true", :url => super_admin_drivers_path}.to_json
    #  redirect_to super_admin_customers_path
    #
    #else
    #  #@errors = @user.errors
    #  #render :json => {:success => "false", :html => render_to_string(:partial => '/layouts/errors')}.to_json
    #  render "edit"
    #end
  end


  def destroy
    user = User.find_by_id(params[:id])
    @driver = user if @partner.drivers.include?(user)
    if @driver.destroy
      flash[:notice] = "Driver was successfully Deleted."
      redirect_to super_admin_partner_path(@partner)
    else
      flash[:alert] = "Something went wrong. Please try again later."
      redirect_to super_admin_driver_path(:id => @driver.id, :partner_id => @driver.partner.id)
    end
  end

  def disable_customer
    @user = User.find_by_id(params[:id])
    if @user.update_attributes(:status => params[:status])
      @customers = User.customers
      render :partial => "super_admin/customers/list"
    end
  end

  private

  def needs_password?(user, params)
    params[:user][:password].present?
  end


end
