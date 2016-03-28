class CouponCode < ActiveRecord::Base
  belongs_to :promotion_code_user, :class_name => 'User'
  attr_accessible :code, :coupon_type, :coupon_value, :valid_from, :valid_to, :user_id, :send_to_users, :per_user, :per_coupon, :status, :promotion_code_user_id, :promotion_code_user_type, :coupon_group, :is_send
  belongs_to :user

  def get_status(coupon_code)
    status = "Open"
    @flag = true
    if Time.now >= coupon_code.valid_from and  Time.now <= coupon_code.valid_to
    else
      @flag = false
    end
    @count = CouponCodeUser.where(:coupon_code_id => coupon_code.id).size
    if coupon_code.per_coupon > 0 and @count >= coupon_code.per_coupon
      @flag = false
    end
    if @flag == false
      status = "Expired"
    else
      status = "Open"
    end
    return status
  end

 end