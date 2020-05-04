class FileUploadController < ApplicationController
  # POST /file_upload.json
  def create
    respond_to do |format|
      upload = CanvasAPI.client.upload_file_to_course(
          file_upload_params.tempfile,
          file_upload_params.original_filename,
          file_upload_params.content_type
      )

      if upload.is_a? Hash and upload[:url]
        format.json { render json: upload, status: :ok }
      else
        info = JSON.parse(upload.body)
        format.json { render json: info, status: 500 }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def file_upload_params
      params.require(:upload)
    end
end
