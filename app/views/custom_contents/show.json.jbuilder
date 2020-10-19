json.partial! "custom_contents/custom_content", custom_content: @custom_content

if @custom_content.content_type == 'wiki_page'
  canvas_name = 'pages'
elsif @custom_content.content_type == 'assignment'
  canvas_name = 'assignments'
end

json.canvas_url "#{CanvasAPI.client.canvas_url}courses/#{@custom_content.course_id}/#{canvas_name}/#{@custom_content.secondary_id}"
