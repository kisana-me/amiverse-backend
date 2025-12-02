module ApplicationHelper
  def full_title(page_title = '')
    base_title = 'Amiverse API'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def full_url(path)
    URI.join(ENV.fetch('BACK_URL'), path).to_s
  end
end
