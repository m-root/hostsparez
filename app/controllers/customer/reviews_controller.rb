class Customer::ReviewsController < Customer::CustomerController

  before_filter :authenticate_user!

  def index
    job = Job.find_by_id(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
    unless @job.driver.blank?
      @driver_reviews = @job.driver.driver_reviews.order("created_at desc")
    else
      @driver_reviews = nil
    end
    @driver_rating_whole, @driver_rating_part = @job.driver.driver_rating
  end

  def new
    job = Job.find_by_id(params[:id])
    @job = job if current_user.customer_jobs.include?(job)
    @driver_rating_whole, @driver_rating_part = @job.driver.driver_rating
    @review = Review.new
  end

  def show

  end


  def create
    @review = Review.new(params[:review])
    if @review.save
      flash[:notice] = ":Review was successfully Added."
      url = "/customer/reviews?id=" + @review.job_id.to_s
      send_notification(@review)
      render :json => {:success => true, :url => url}.to_json
    else
      @errors = @review.errors
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def send_notification(review)
    if review.driver.blank?
      return
    end
    return unless review.driver.device_token.present?
    notification = Houston::Notification.new(:device => review.driver.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => @review.id, :type => @review.class.to_s}
    notification.alert = "New message created"
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end


end
