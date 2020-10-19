json.extract! custom_content, :id, :title, :body, :published_at, :content_type, :created_at, :updated_at, :course_id,
        :course_name, :secondary_id
json.url custom_content_url(custom_content, format: :json)
