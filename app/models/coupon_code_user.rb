class CouponCodeUser < ActiveRecord::Base
  attr_accessible  :user_id, :job_id, :coupon_code_id
end
