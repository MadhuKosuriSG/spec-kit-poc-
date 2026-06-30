class AuthTokenService
  SECRET = Rails.application.credentials.jwt_secret_key || Rails.application.secret_key_base

  TOKEN_EXPIRY = 7.days

  def self.encode(user)
    now = Time.now.to_i
    payload = {
      sub: user.id,
      email: user.email,
      iat: now,
      exp: now + TOKEN_EXPIRY.to_i
    }
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, algorithms: [ "HS256" ]).first
  end
end
