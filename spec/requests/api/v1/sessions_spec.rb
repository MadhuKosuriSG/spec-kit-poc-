require "rails_helper"

RSpec.describe "POST /api/v1/sessions", type: :request do
  let(:password) { "securepass123" }
  let!(:user) { create(:user, email: "jane@example.com", password: password) }

  def post_login(params)
    post "/api/v1/sessions", params: params.to_json, headers: { "Content-Type" => "application/json" }
  end

  describe "Scenario 1: valid credentials" do
    it "returns 200 with a JWT token" do
      post_login(email: "jane@example.com", password: password)
      expect(response).to have_http_status(:ok)
      expect(json_body["token"]).to be_present
    end

    it "token contains correct sub (user id)" do
      post_login(email: "jane@example.com", password: password)
      payload = decoded_token(json_body["token"])
      expect(payload["sub"]).to eq(user.id)
    end

    it "token contains correct email" do
      post_login(email: "jane@example.com", password: password)
      payload = decoded_token(json_body["token"])
      expect(payload["email"]).to eq(user.email)
    end

    it "does not expose password or password_digest in response" do
      post_login(email: "jane@example.com", password: password)
      expect(response.body).not_to include("password")
      expect(response.body).not_to include("password_digest")
    end
  end

  describe "Scenario 2: wrong password" do
    it "returns 401 with generic error" do
      post_login(email: "jane@example.com", password: "wrongpassword")
      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to eq("Invalid email or password")
    end
  end

  describe "Scenario 3: unknown email" do
    it "returns 401 with the same generic error (no email enumeration)" do
      post_login(email: "nobody@example.com", password: password)
      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to eq("Invalid email or password")
    end
  end

  describe "Scenario 4: missing fields" do
    it "returns 422 when email is blank" do
      post_login(email: "", password: password)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end

    it "returns 422 when password is blank" do
      post_login(email: "jane@example.com", password: "")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "password")).to be_present
    end
  end

  describe "edge case: case-insensitive email matching" do
    it "authenticates with uppercase email" do
      post_login(email: "JANE@EXAMPLE.COM", password: password)
      expect(response).to have_http_status(:ok)
      expect(json_body["token"]).to be_present
    end
  end

  def json_body
    JSON.parse(response.body)
  end

  def decoded_token(token)
    JWT.decode(token, AuthTokenService::SECRET, true, algorithms: [ "HS256" ]).first
  end
end
