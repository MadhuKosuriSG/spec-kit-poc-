module Authorization
  extend ActiveSupport::Concern

  private

  def require_admin!
    return if current_user&.admin?

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
