class UsersController < ApplicationController
  before_action :set_project

  respond_to :html, :json

  def index
    @available_users = available_users
    respond_with(@project.users)
  end

  def create
    @user = User.new(allowed_params)
    authorize @user
    if @user.save
      MembershipOperations::Create.call(project: @project, user: @user)
      flash.notice = "#{@user.email} was added to the project"
    else
      flash.alert = "User was not created"
    end

    respond_to do |format|
      format.js { render :refresh_user_list }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def destroy
    @user = policy_scope(User).find(params[:id])
    authorize @user
    @available_users = available_users

    ActiveRecord::Base.transaction do
      RemoveStoriesFromUserService.call(@user, @project)
      policy_scope(User).delete(@user)
    end

    flash.notice = I18n.t('was removed from this project', scope: 'users', email: @user.email)

    respond_to do |format|
      format.js { render :refresh_user_list }
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def available_users
    User.where.not(id: @project.users).order(:name)
  end

  def allowed_params
    params.require(:user).permit(:email, :name, :initials, :username)
  end

  def set_project
    @project = policy_scope(Project).friendly.find(params[:project_id])
  end
end
