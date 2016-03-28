class CouponEmail < Struct.new(:coupon_code, :email_notify_users, :protocol, :host)

  def perform
    unless email_notify_users.blank?
      UserMailer.new_coupon(coupon_code, email_notify_users, protocol, host).deliver
    end
  end


end


