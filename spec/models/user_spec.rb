require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_length_of(:email).is_at_most(255) }
    it { is_expected.to have_secure_password }
    it { is_expected.to validate_length_of(:password).is_at_least(8).on(:create) }

    it "rejects invalid email formats" do
      user.email = "not-an-email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "accepts valid email formats" do
      user.email = "valid@example.com"
      expect(user).to be_valid
    end
  end

  describe "normalisation" do
    it "downcases and strips email before validation" do
      user.email = "  User@Example.COM  "
      user.valid?
      expect(user.email).to eq("user@example.com")
    end

    it "strips whitespace from name before validation" do
      user.name = "  Jane  "
      user.valid?
      expect(user.name).to eq("Jane")
    end

    it "treats email with different casing as duplicate" do
      create(:user, email: "user@example.com")
      duplicate = build(:user, email: "User@Example.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it "treats whitespace-only name as blank" do
      user.name = "   "
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "treats whitespace-only email as blank" do
      user.email = "   "
      expect(user).not_to be_valid
    end
  end

  describe "length limits" do
    it "rejects name longer than 255 characters" do
      user.name = "a" * 256
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "rejects email longer than 255 characters" do
      user.email = "#{"a" * 244}@example.com"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end
  end
end
