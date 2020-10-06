class BaseCoursesController < ApplicationController
  layout 'admin'

  # GET /course_management
  def index
    authorize BaseCourse
  end

  # GET /course{,template}s/1
  def show
    authorize @base_course
  end

  # GET /course{,template}s/new
  def new
    @base_course = BaseCourse.new(new_params)
    authorize @base_course
  end

  # GET /course{,template}s/1/edit
  def edit
    authorize @base_course
  end

  # POST /course{,template}s
  def create
    @base_course = BaseCourse.new(base_course_params)
    authorize @base_course
    respond_to do |format|
      if @base_course.save
        format.html { redirect_to base_courses_path, notice: "#{set_type.humanize} was successfully created." }
        format.json { render :show, status: :created, location: @base_course }
      else
        format.html { render :new }
        format.json { render json: @base_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /course{,template}s/1
  def update
    authorize @base_course
    respond_to do |format|
      if @base_course.update(base_course_params)
        format.html { redirect_to base_courses_path, notice: "#{set_type.humanize} was successfully updated." }
        format.json { render :show, status: :ok, location: @base_course }
      else
        format.html { render :edit }
        format.json { render json: @base_course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /course{,template}s/1
  def destroy
    authorize @base_course
    @base_course.destroy
    respond_to do |format|
      format.html { redirect_to base_courses_url, notice: "#{set_type.humanize} was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  # Note to readers - not sure why this is called set_type, if that's a Rails thing or
  # not. More context here https://youtu.be/2fH_V91b0H4?t=416. What this actually does
  # is similar to the `*_params` methods, just return safe strings given arbitrary param
  # inputs.
  def set_type
    case params[:type]
    when 'Course'
      'course'
    when 'CourseTemplate'
      'course_template'
    end
  end

  def base_course_params
    params.require(set_type).permit(:name, :type, :course_resource_id, :canvas_course_id)
  end

  def new_params
    params.permit(:type)
  end
end
