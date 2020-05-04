json.partial! "course_contents/course_content", course_content: @course_content

if @course_content.content_type == 'wiki_page'
  canvas_name = 'pages'
elsif @course_content.content_type == 'assignment'
  canvas_name = 'assignments'
end

json.canvas_url "#{CanvasAPI.client.canvas_url}courses/#{@course_content.course_id}/#{canvas_name}/#{@course_content.secondary_id}"
