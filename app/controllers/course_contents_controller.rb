class CourseContentsController < ApplicationController
  layout 'content_editor'
  before_action :set_course_content, only: [:show, :edit, :update, :destroy, :publish]
  before_action :set_course_contents, only: [:index, :edit, :new]

  # GET /course_contents
  # GET /course_contents.json
  def index
  end

  # GET /course_contents/1
  # GET /course_contents/1.json
  def show
  end

  # GET /course_contents/new
  def new
    @course_contents = CourseContent.all
    @course_content = CourseContent.new
  end

  # GET /course_contents/1/edit
  def edit
    @course_contents = CourseContent.all
  end

  # POST /course_contents
  # POST /course_contents.json
  def create
    @course_content = CourseContent.new(course_content_params)

    respond_to do |format|
      if @course_content.save
        format.html { redirect_to edit_course_content_path(@course_content), notice: 'CourseContent was successfully created.' }
        format.json { render :show, status: :created, location: @course_content }
      else
        format.html { render :new }
        format.json { render json: @course_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /course_contents/1
  # PATCH/PUT /course_contents/1.json
  def update
    respond_to do |format|
      if @course_content.update(course_content_params)
        format.html { redirect_to edit_course_content_path(@course_content), notice: 'CourseContent was successfully updated.' }
        format.json { render :show, status: :ok, location: @course_content }
      else
        format.html { render :edit }
        format.json { render json: @course_content.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /course_contents/1
  # DELETE /course_contents/1.json
  def destroy
    @course_content.destroy
    respond_to do |format|
      format.html { redirect_to course_contents_url, notice: 'CourseContent was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # POST /course_contents/1/publish
  # POST /course_contents/1/publish.json
  def publish
    respond_to do |format|
      if @course_content.publish(course_content_params)

        # update publish time, save a version
        @course_content.published_at = DateTime.now
        new_version = CourseContentHistory.new({
          course_content_id: @course_content.id,
          title: @course_content.title,
          body: @course_content.body,
          user: @current_user,
        })
        @course_content.transaction do
          new_version.save!
          @course_content.save!
        end

        # return
        format.html { redirect_to @course_content, notice: 'CourseContent was successfully published.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @course_content.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_course_content
      @course_content = CourseContent.find(params[:id])
    end

    def set_course_contents
      @course_contents = CourseContent.all
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def course_content_params
      params.require(:course_content).permit(:title, :body, :published_at, :content_type, :course_id, :course_name, :secondary_id)
    end
end
