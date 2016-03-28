class Driver::MessagesController < Driver::DriverController
  layout "driver"
  before_filter :authenticate_user!

  before_filter do
    redirect_to root_url unless current_user.driver?
  end

  def message_sent
    render :layout => false
  end

  def index
    #abc = []
    #abc << Message.find(115)
    #abc << Message.find(110)
    #unless abc.include?(Message.find(115))
    #  puts "SSS"
    #end
    #ss
    @all_messages = Message.where(:receiver_id => current_user.id, :receiver_deleted => false).order("created_at desc")
    @messages = @all_messages.paginate(:page => params[:page], :per_page => 5)
  end

  def new
    job = Job.find_by_id(params[:id])
    @job = job if current_user.driver_jobs.include?(job)
    @message = Message.new
  end

  def create
    @message = Message.new(params[:message])
    if @message.save
      flash[:notice] = ":Message was successfully Added."
      url = driver_messages_path
      #send_notification(@message)
      render :json => {:success => true, :url => url}.to_json
    else
      @errors = @message.errors
      @message = nil
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def send_notification(message)
    if message.receiver.blank?
      return
    end
    return unless message.receiver.device_token.present?
    notification = Houston::Notification.new(device: message.receiver.device_token)
    notification.badge = 0
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {:id => @message.id, :type => @message.class.to_s}
    notification.alert = "New message created"
    certificate = File.read("config/production_driver.pem")
    pass_phrase = "push"
    connection = Houston::Connection.new("apn://gateway.push.apple.com:2195", certificate, pass_phrase)
    connection.open
    connection.write(notification.message)
    connection.close
  end

  def show
    message = Message.find_by_id(params[:id])
    @message = message if current_user.received_messages.include?(message)
  end

  def get_message
    message = Message.find_by_id(params[:id])
    @message = message if Message.full_messages(current_user.id).include?(message)
    @message.update_attribute(:status, "open")
    if @message.parent.blank?
      @parent_message = @message
    else
      @parent_message = @message.parent
    end

    render :partial => "driver/messages/message_detail"
  end

  def del_pop_up
    @message = Message.find_by_id(params[:id])
    #@message = message if current_user.received_messages.include?(message)
    render :layout => false
  end

  def reply
    @received_message = Message.find_by_id(params[:id])
    @message = Message.new
    render :partial => "driver/messages/message_reply"
  end

  def delete_message
    @message = Message.find_by_id(params[:id])
    #@message = message if current_user.received_messages.include?(message)
    @message.update_attribute(:receiver_deleted, true)
    #@message.destroy
    render :layout => false
  end


end
