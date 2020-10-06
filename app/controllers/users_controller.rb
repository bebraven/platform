# frozen_string_literal: true
class UsersController < ApplicationController
  layout 'admin'

  before_action :find_user, only: %i[show edit update confirm destroy]

  def index
    authorize User
    current_page = params[:page]
    @users = if params[:search]
               User.search(params[:search])
             else
               User.order(created_at: :desc)
             end

    respond_to do |format|
      format.html do
        @users = @users.paginate(page: current_page)
        render
      end
    end
  end

  def show
    authorize @user
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    authorize User
    @user = User.create(user_params.merge(confirmed_at: DateTime.now))

    if @user.persisted?
      redirect_to users_path, notice: 'User was added successfully'
    else
      render action: :new
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user

    # Don't update the password if it's blank (unchanged).
    filtered_user_params = user_params.reject { |k, v| k == "password" and v.blank? }
    user_changes_persisted = @user.update(filtered_user_params)

    if user_changes_persisted
      redirect_to user_path(@user), notice: 'User was changed successfully'
    else
      render action: :edit
    end
  end

  def confirm
    authorize @user

    if @user.confirmed?
      redirect_to user_path(@user), notice: 'User already confirmed'
    else
      @user.confirm
      redirect_to user_path(@user), notice: 'User has been confirmed'
    end
  end

  def destroy
    authorize @user
    @user.delete
    redirect_to users_path, notice: 'User has been deleted'
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :canvas_id, :salesforce_id, role_ids: [])
  end
end
