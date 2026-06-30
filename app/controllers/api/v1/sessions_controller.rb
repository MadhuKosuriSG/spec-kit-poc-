module Api
  module V1
    class SessionsController < ApplicationController
      def create
        blank_errors = validate_presence
        if blank_errors.any?
          render json: { errors: blank_errors }, status: :unprocessable_entity
          return
        end

        user = User.find_by(email: session_params[:email].to_s.strip.downcase)
        if user&.authenticate(session_params[:password])
          render json: { token: AuthTokenService.encode(user) }, status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      private

      def session_params
        params.permit(:email, :password)
      end

      def validate_presence
        errors = {}
        errors[:email] = [ "can't be blank" ] if session_params[:email].blank?
        errors[:password] = [ "can't be blank" ] if session_params[:password].blank?
        errors
      end
    end
  end
end
