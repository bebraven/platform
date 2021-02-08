class Users::PortalPasswordController < UsersController
  
  before_action :find_user, only: %i[show edit update]

  # GET	/users/portal_password/5823/edit 
  def edit
    authorize @user
  end 

  # POST	/users/portal_password/:id
  def update 
    authorize @user
  end 

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :canvas_user_id, :salesforce_id, role_ids: [])
  end

end 