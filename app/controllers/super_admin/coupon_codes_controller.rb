require 'will_paginate/array'
class SuperAdmin::CouponCodesController < SuperAdmin::SuperAdminController

  def new
    @coupon_code =CouponCode.new
  end

  def edit
    @coupon_code =Blog.find(params[:id])
  end


  def create
    unless params[:coupon_code][:valid_from].blank?
      time = Time.strptime(params[:coupon_code][:valid_from], '%m-%d-%Y')
      params[:coupon_code][:valid_from] = time.strftime("%Y/%m/%d")
    end
    unless params[:coupon_code][:valid_to].blank?
      time = Time.strptime(params[:coupon_code][:valid_to], '%m-%d-%Y')
      params[:coupon_code][:valid_to] = time.strftime("%Y/%m/%d")
    end
    if params[:coupon_code][:per_user] == ""
      params[:coupon_code][:per_user] = 0
    end
    if params[:coupon_code][:per_coupon] == ""
      params[:coupon_code][:per_coupon] = 0
    end
    @coupon_code = CouponCode.new(params[:coupon_code])
    if @coupon_code.save
      flash[:notice] = ":Coupon Code was successfully Added."
      user_array = []
      if @coupon_code.is_send == true
        if @coupon_code.coupon_group != "none"
          if @coupon_code.promotion_code_user_id == 0
            if @coupon_code.coupon_group == "all"
              users = User.all
            elsif @coupon_code.coupon_group == "customers"
              users = User.customers
            elsif @coupon_code.coupon_group == "drivers"
              users = User.drivers
            end
            users.each do |user|
              user_array << user
            end
            emails = CouponEmail.new(@coupon_code, user_array, request.protocol, request.host_with_port)
            Delayed::Job.enqueue(emails)
          else
            if @coupon_code.promotion_code_user.present?
              user = @coupon_code.promotion_code_user
              user_array << user
              emails = CouponEmail.new(@coupon_code, user_array, request.protocol, request.host_with_port)

              Delayed::Job.enqueue(emails)
            end
          end
        end
      end
      #redirect_to super_admin_blogs_path
      render :json => {:success => true, :url => super_admin_coupon_codes_path}.to_json
    else
      render :new
      @errors = @coupon_code.errors
      #@message = nil
      render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def update
    @coupon_code = Blog.find_by_id(params[:id])
    if @coupon_code.update_attributes(params[:blog])
      flash[:notice] = "Blog was successfully updated."
      redirect_to super_admin_blogs_path
    else
      render :edit
    end
  end

  def index
    @coupon_code =CouponCode.new
    @users = User.all
    @coupon_codes = CouponCode.all
    @coupon_codes = @coupon_codes.paginate(:page => params[:page], :per_page => 10)
    if params[:page].present?
      render :partial => "super_admin/coupon_codes/coupon_list"
    end
  end

  def get_users
    if params[:id] == "all"
      @users = User.all
    elsif params[:id] == "customers"
      @users = User.customers
    elsif params[:id] == "drivers"
      @users = User.drivers
    end
    render :partial => "super_admin/coupon_codes/user_drop_down"
  end

  def search_coupon
     @coupon_codes = CouponCode.all
     if params[:code].present?
       @coupon_codes = @coupon_codes.where(:code => params[:code])
     end
     if params[:valid_from].present?
       @coupon_codes = @coupon_codes.select{|coupon_code| coupon_code.valid_from.strftime("%m-%d-%Y").downcase >= params[:valid_from].downcase}
     end
     if params[:valid_to].present?
       @coupon_codes = @coupon_codes.select{|coupon_code| coupon_code.valid_to.strftime("%m-%d-%Y").downcase <= params[:valid_to].downcase}
     end
     if params[:status].present?
       if params[:status] == "Open"
         @coupon_codes = @coupon_codes.select{|coupon_code| coupon_code.status == params[:status]}
       elsif  params[:status] == "Expired"
         @coupon_codes = @coupon_codes.select{|coupon_code| coupon_code.status == params[:status]}
       end
     end
     if params[:last_name].present?
       @coupon_codes = @coupon_codes.select{|coupon_code| coupon_code.promotion_code_user.present? ? coupon_code.promotion_code_user.last_name == params[:last_name] : nil}
     end
     @coupon_codes = @coupon_codes.paginate(:page => params[:page], :per_page => 10)
     render :partial => "super_admin/coupon_codes/coupon_list"
    #sss
  end

  def disable_blog
    @coupon_code = Blog.find_by_id(params[:id])
    if @coupon_code.update_attributes(:is_archived => params[:status])
      @coupon_codes = Blog.all
      render :partial => "super_admin/blogs/list"
    end
  end

end
