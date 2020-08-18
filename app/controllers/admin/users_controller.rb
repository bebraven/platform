# frozen_string_literal: true

# Admin User Controller
class Admin::UsersController < ApplicationController
  layout 'admin'

  before_action :find_user, only: %i[show edit update confirm destroy]

  def index
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

  def show; end

  def new
    @user = User.new
  end

  def create
    User.skip_callback(:validation, :before, :do_account_registration)
    @user = User.create(user_params.merge(confirmed_at: DateTime.now))
    User.set_callback(:validation, :before, :do_account_registration)

    if @user.persisted?
      redirect_to admin_users_path, notice: 'User was added successfully'
    else
      render action: :new
    end
  end

  def edit; end

  def update
    filtered_user_params = user_params.reject { |_, v| v.blank? }

    User.skip_callback(:validation, :before, :do_account_registration)
    user_changes_persisted = @user.update_attributes(filtered_user_params)
    User.set_callback(:validation, :before, :do_account_registration)

    if user_changes_persisted
      redirect_to admin_user_path(@user), notice: 'User was changed successfully'
    else
      render action: :edit
    end
  end

  def confirm
    if @user.confirmed?
      redirect_to admin_user_path(@user), notice: 'User already confirmed'
    else
      @user.confirm
      redirect_to admin_user_path(@user), notice: 'User has been confirmed'
    end
  end

  def destroy
    @user.delete
    redirect_to admin_users_path, notice: 'User has been deleted'
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :admin, :canvas_id, :salesforce_id)
  end
end
