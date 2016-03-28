class Driver::ReportingsController < Driver::DriverController
  #layout "driver"
  before_filter :authenticate_user!

  before_filter do
    redirect_to root_url unless current_user.driver?
  end

  def index

  end

  def get_driver_delivery_stats
    @user = current_user
    if params[:date_crt] == "All Time"
      @jobs = @user.driver_jobs
    elsif params[:date_crt] == "Today"
      @jobs = @user.driver_jobs.where("Date(delivered_date) = ?", Date.today)
    elsif params[:date_crt] == "This Week"
      @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 7, Date.today)
    elsif params[:date_crt] == "This Month"
      @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 30, Date.today)
    elsif params[:date_crt] == "Last Month"
      @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 60, Date.today - 30)
    elsif params[:date_crt] == "Year to Date"
      @jobs = @user.driver_jobs.where("Date(delivered_date) >= ? and Date(delivered_date) <= ?", Date.today- 365, Date.today)
    end
    total_revenue = 0
    deliveries_count = 0
    ziply_revenue = 0
    driver_earning = 0
    unless @jobs.blank?
      @jobs.each_with_index do |job, index|
        if job.transaction_history.present?
          unless job.transaction_history.amount.blank?
            total_revenue += job.transaction_history.amount
            deliveries_count = deliveries_count + 1
            ziply_revenue += job.transaction_history.ziply_revenue if job.transaction_history.ziply_revenue
            driver_earning += job.transaction_history.driver_amount if job.transaction_history.driver_amount
          end
        end
      end
    end
    @total_revenue = total_revenue
    @deliveries_count = deliveries_count
    @ziply_revenue = ziply_revenue
    @driver_earning = driver_earning
    render :partial => "driver/reportings/delivery_stats"
  end

  def get_driver_stats
    @user = current_user
    if params[:date_crt] == "All Time"
      puts "FFF"
      @travelling_times = @user.travelling_times
    elsif params[:date_crt] == "Today"
      @travelling_times = @user.travelling_times.where("Date(created_at) = ?", Date.today)
    elsif params[:date_crt] == "This Week"
      @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 7, Date.today)
    elsif params[:date_crt] == "This Month"
      @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 30, Date.today)
    elsif params[:date_crt] == "Last Month"
      @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 60, Date.today - 30)
    elsif params[:date_crt] == "Year to Date"
      @travelling_times = @user.travelling_times.where("Date(created_at) >= ? and Date(created_at) <= ?", Date.today- 365, Date.today)
    end
    total_time = 0
    distance = 0
    unless @travelling_times.blank?
      @travelling_times.each do |travelling_time|
        if travelling_time.clock_in.present? and travelling_time.clock_out.present?
          total_time += ((travelling_time.clock_out - travelling_time.clock_in) / 3600)
        elsif travelling_time.clock_in.present? and travelling_time.clock_out.blank?
          total_time += ((Time.now - travelling_time.clock_in) / 3600)
        end
        if travelling_time.total_miles.present?
          distance += travelling_time.total_miles
        end
      end
    end
    @total_time =total_time
    @total_distance =distance
    render :partial => "driver/reportings/driver_stats"
  end


end
