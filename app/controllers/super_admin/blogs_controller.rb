class SuperAdmin::BlogsController < SuperAdmin::SuperAdminController

  def new
    @blog =Blog.new
  end

  def edit
    @blog =Blog.find(params[:id])
  end

  def create
    @blog = Blog.new(params[:blog])
    if @blog.save
      flash[:notice] = ":Blog was successfully Added."
      redirect_to super_admin_blogs_path
      #render :json => {:success => true, :url => super_admin_blogs_path}.to_json
    else
      render :new
      #@errors = @blog.errors
      #@message = nil
      #render :json => {:success => false, :html => render_to_string(:partial => '/layouts/errors')}.to_json
    end
  end

  def update
    @blog = Blog.find_by_id(params[:id])
    if @blog.update_attributes(params[:blog])
      flash[:notice] = "Blog was successfully updated."
      redirect_to super_admin_blogs_path
    else
      render :edit
    end
  end

  def index
    @blogs = Blog.where(:is_archived => false)
  end

  def disable_blog
    @blog = Blog.find_by_id(params[:id])
    if @blog.update_attributes(:is_archived => params[:status])
      @blogs = Blog.all
      render :partial => "super_admin/blogs/list"
    end
  end

end
