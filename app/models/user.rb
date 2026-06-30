class User < ApplicationRecord
  has_secure_password

  validates :name, presence: true, length: { maximum: 255 }
  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false },
            length: { maximum: 255 }
  validates :password, length: { minimum: 8 }, allow_nil: true

  before_validation :normalize_fields

  private

  def normalize_fields
    self.email = email.to_s.strip.downcase
    self.name = name.to_s.strip
  end
end
