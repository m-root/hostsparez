module ApplicationHelper
  def strtime(time)
    time.strftime("%m/%d/%Y %H:%M:%S")
  end
  def title(page_title)
    content_for(:title) { page_title }
  end
  def description(page_description)
    content_for(:description) { page_description }
  end
end
