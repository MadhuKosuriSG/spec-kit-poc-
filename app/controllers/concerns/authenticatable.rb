module Authenticatable
  extend ActiveSupport::Concern

  private

  def current_user
    @current_user ||= user_from_token
  end

  def user_from_token
    payload = AuthTokenService.decode(bearer_token)
    User.find_by(id: payload["sub"])
  rescue JWT::DecodeError, TypeError
    nil
  end

  def bearer_token
    header = request.headers["Authorization"]
    header.split(" ").last if header&.start_with?("Bearer ")
  end
end
