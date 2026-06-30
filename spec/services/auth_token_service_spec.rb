require "rails_helper"

RSpec.describe AuthTokenService do
  let(:user) { create(:user) }

  describe ".encode" do
    subject(:token) { described_class.encode(user) }

    it "returns a non-nil JWT string" do
      expect(token).to be_a(String)
      expect(token).not_to be_empty
    end

    it "encodes sub as the user id" do
      payload = JWT.decode(token, described_class::SECRET, true, algorithms: [ "HS256" ]).first
      expect(payload["sub"]).to eq(user.id)
    end

    it "encodes email as the user email" do
      payload = JWT.decode(token, described_class::SECRET, true, algorithms: [ "HS256" ]).first
      expect(payload["email"]).to eq(user.email)
    end

    it "sets iat to approximately now" do
      payload = JWT.decode(token, described_class::SECRET, true, algorithms: [ "HS256" ]).first
      expect(payload["iat"]).to be_within(5).of(Time.now.to_i)
    end

    it "sets exp to approximately 7 days from now" do
      payload = JWT.decode(token, described_class::SECRET, true, algorithms: [ "HS256" ]).first
      expect(payload["exp"]).to be_within(5).of((Time.now + 7.days).to_i)
    end

    it "signs with HS256" do
      header = JSON.parse(Base64.decode64(token.split(".").first))
      expect(header["alg"]).to eq("HS256")
    end
  end

  describe ".decode" do
    let(:token) { described_class.encode(user) }

    it "returns a hash with correct sub" do
      payload = described_class.decode(token)
      expect(payload["sub"]).to eq(user.id)
    end

    it "returns a hash with correct email" do
      payload = described_class.decode(token)
      expect(payload["email"]).to eq(user.email)
    end

    it "raises JWT::DecodeError for a tampered token" do
      tampered = token + "tampered"
      expect { described_class.decode(tampered) }.to raise_error(JWT::DecodeError)
    end

    it "raises JWT::ExpiredSignature for an expired token" do
      expired_payload = {
        sub: user.id,
        email: user.email,
        iat: 1.hour.ago.to_i,
        exp: 30.minutes.ago.to_i
      }
      expired_token = JWT.encode(expired_payload, described_class::SECRET, "HS256")
      expect { described_class.decode(expired_token) }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
