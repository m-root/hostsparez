class Customer::DashboardController < Customer::CustomerController
  before_filter :authenticate_user!

  def index
    #@active_jobs = current_user.customer_jobs.where(:status => "accepted").order("created_at desc")
    #@all_recent_jobs = current_user.customer_jobs.where(:status => "delivered").order("created_at desc")
    #@recent_jobs = @all_recent_jobs.paginate(:page => params[:page], :per_page => 3)
    #@messages = Message.where(:receiver_id => current_user.id).order("created_at desc").limit(3)
    redirect_to customer_jobs_path
  end
end
