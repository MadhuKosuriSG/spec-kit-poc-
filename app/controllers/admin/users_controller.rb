module Admin
  class UsersController < ApplicationController
    before_action :require_admin!
    before_action :set_user, only: [ :show, :role ]

    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "User not found" }, status: :not_found
    end

    def index
      render json: { users: User.all.map { |user| user_json(user) } }, status: :ok
    end

    def show
      render json: { user: user_json(@user) }, status: :ok
    end

    def role
      requested_role = params[:role].to_s

      if requested_role.blank?
        render json: { errors: { role: [ "can't be blank" ] } }, status: :unprocessable_entity
        return
      end

      unless User.roles.key?(requested_role)
        render json: { errors: { role: [ "must be one of: #{User.roles.keys.join(', ')}" ] } }, status: :unprocessable_entity
        return
      end

      @user.update!(role: requested_role)
      render json: { user: user_json(@user) }, status: :ok
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_json(user)
      { id: user.id, name: user.name, email: user.email, role: user.role }
    end
  end
end
