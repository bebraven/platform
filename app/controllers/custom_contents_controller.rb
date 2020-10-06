class CustomContentsController < ApplicationController
  layout 'content_editor'
  before_action :set_model_instance, only: [:show, :edit, :update, :destroy, :publish]
  before_action :set_custom_contents, only: [:index, :edit, :new]

  # GET /custom_contents
  # GET /custom_contents.json
  def index
    authorize CustomContent
  end

  # GET /custom_contents/1
  # GET /custom_contents/1.json
  def show
    authorize @custom_content
  end

  # GET /custom_contents/new
  def new
    @custom_content = CustomContent.new
    authorize @custom_content
  end

  # GET /custom_contents/1/edit
  def edit
    authorize @custom_content
  end

  # POST /custom_contents
  # POST /custom_contents.json
  def create
    @custom_content = CustomContent.new(custom_content_params)
    authorize @custom_content

    respond_to do |format|
      if @custom_content.save
        format.html { redirect_to edit_custom_content_path(@custom_content), notice: 'CustomContent was successfully created.' }
        format.json { render :show, status: :created, location: @custom_content }
      else
        format.html { render :new }
        format.json { render json: @custom_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /custom_contents/1
  # PATCH/PUT /custom_contents/1.json
  def update
    authorize @custom_content
    respond_to do |format|
      if @custom_content.update(custom_content_params)
        format.html { redirect_to edit_custom_content_path(@custom_content), notice: 'CustomContent was successfully updated.' }
        format.json { render :show, status: :ok, location: @custom_content }
      else
        format.html { render :edit }
        format.json { render json: @custom_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /custom_contents/1
  # DELETE /custom_contents/1.json
  def destroy
    authorize @custom_content
    @custom_content.destroy
    respond_to do |format|
      format.html { redirect_to custom_contents_url, notice: 'CustomContent was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /custom_contents/1/publish
  # POST /custom_contents/1/publish.json
  # This is for publishing content to *portal.bebraven.org (aka Portal).
  # To publish to braven.instructure.com (aka Canvas LMS), we use LTI:
  #  - For modules/courses/lessons: LessonContentsController
  #  - F projects/assignments: LTIAssignmentSelectionController
  def publish
    authorize @custom_content
    respond_to do |format|
      if @custom_content.publish(custom_content_params)

        # update publish time, save a version
        @custom_content.save_version!(@current_user)

        format.html { redirect_to @custom_content, notice: 'CustomContent was successfully published.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @custom_content.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  def set_custom_contents
    @custom_contents = CustomContent.all
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def custom_content_params
    params.require(:custom_content).permit(:title, :body, :published_at, :content_type, :course_id, :course_name, :secondary_id)
  end
end
