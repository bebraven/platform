module ApplicationHelper
  def nav_link label, url, options={}
    options[:feather] ||= 'arrow-right-circle'
    
    text = "<span data-feather=\"#{options[:feather]}\"></span> #{label}".html_safe

    html_class = 'nav-link'
    
    if (options[:controller] ? (controller.controller_path == options[:controller]) : current_page?(url))
      html_class += ' active'
    end
    
    html_class += " #{controller.controller_path}"
    
    link_to(text, url, class: html_class)
  end
  
  def previous_page collection
    "#{request.base_url}#{request.path}?page=#{collection.previous_page}"
  end
  
  def next_page collection
    "#{request.base_url}#{request.path}?page=#{collection.next_page}"
  end
  
  def success notice
    return '' if notice.nil?
    
    %Q(
      <div class="alert alert-success alert-dismissable fade show" role="alert">
        <strong>Success!</strong> #{notice}
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    ).html_safe
  end

  def failure notice
    return '' if notice.nil?
    
    %Q(
      <div class="alert alert-danger alert-dismissable fade show" role="alert">
        <strong>Woops!</strong> #{notice}
        <button type="button" class="close" data-dismiss="alert" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
    ).html_safe
  end

  def is_production_app?
    ENV['HEROKU_APP_NAME'] == 'braven-platform'
  end

  def portal_stylesheet_link_tag
    # Choose S3 resource based on where we're running.
    assets = if is_production_app?
      "canvas-prod-assets"
    else
      "canvas-stag-assets"
    end

    # Automatically change the "version" string to fix caching issues.
    version = ENV['HEROKU_RELEASE_VERSION']

    stylesheetURL = "https://s3.amazonaws.com/#{assets}/braven_newui.css?v=#{version}"

    # Return full HTML link element.
    "<link rel='stylesheet' href='#{stylesheetURL}'>".html_safe
  end
end
