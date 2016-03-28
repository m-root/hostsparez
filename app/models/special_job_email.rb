class SpecialJobEmail < Struct.new(:job, :user, :protocol, :host, :email_status)

  def perform
    if email_status == 'job_accepted'
      UserMailer.job_accepted(job, user, protocol, host).deliver
    elsif email_status == 'job_picked'
      UserMailer.job_picked(job, user, protocol, host).deliver
      UserMailer.recipient_order(job, protocol, host).deliver
    elsif email_status == 'job_delivered'
      UserMailer.job_delivered(job, user, protocol, host).deliver
    end
  end

end


