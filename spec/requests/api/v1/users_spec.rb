require "rails_helper"

RSpec.describe "POST /api/v1/users", type: :request do
  let(:valid_params) do
    {
      user: {
        name: "Jane Doe",
        email: "jane@example.com",
        password: "securepass123"
      }
    }
  end

  def post_registration(params)
    post "/api/v1/users", params: params.to_json, headers: { "Content-Type" => "application/json" }
  end

  describe "Scenario 1: valid registration" do
    it "returns 201 with success message" do
      post_registration(valid_params)
      expect(response).to have_http_status(:created)
      expect(json_body["message"]).to eq("Account created successfully")
    end

    it "does not expose password or password_digest in response" do
      post_registration(valid_params)
      expect(response.body).not_to include("password")
      expect(response.body).not_to include("password_digest")
    end

    it "creates the user in the database" do
      expect { post_registration(valid_params) }.to change(User, :count).by(1)
    end
  end

  describe "Scenario 2: duplicate email" do
    before { create(:user, email: "jane@example.com") }

    it "returns 422 with email error" do
      post_registration(valid_params)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end
  end

  describe "Scenario 3: invalid email format" do
    it "returns 422 with email error" do
      post_registration(valid_params.deep_merge(user: { email: "not-an-email" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end
  end

  describe "Scenario 4: password too short" do
    it "returns 422 with password error" do
      post_registration(valid_params.deep_merge(user: { password: "short" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "password")).to be_present
    end
  end

  describe "Scenario 5: missing required fields" do
    it "returns 422 when name is missing" do
      post_registration(valid_params.deep_merge(user: { name: "" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "name")).to be_present
    end

    it "returns 422 when email is missing" do
      post_registration(valid_params.deep_merge(user: { email: "" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end

    it "returns 422 when password is missing" do
      post_registration(valid_params.deep_merge(user: { password: "" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "password")).to be_present
    end
  end

  describe "edge cases" do
    it "treats uppercase email as duplicate of lowercase" do
      create(:user, email: "jane@example.com")
      post_registration(valid_params.deep_merge(user: { email: "JANE@EXAMPLE.COM" }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end

    it "treats whitespace-only name as blank" do
      post_registration(valid_params.deep_merge(user: { name: "   " }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "name")).to be_present
    end

    it "returns 422 for name longer than 255 characters" do
      post_registration(valid_params.deep_merge(user: { name: "a" * 256 }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "name")).to be_present
    end

    it "returns 422 for email longer than 255 characters" do
      long_email = "#{"a" * 244}@example.com"
      post_registration(valid_params.deep_merge(user: { email: long_email }))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "email")).to be_present
    end
  end

  def json_body
    JSON.parse(response.body)
  end
end
