require "rails_helper"

RSpec.describe "Admin::UsersController", type: :request do
  let(:admin) { create(:user, role: :admin) }
  let(:regular_user) { create(:user, role: :user) }

  def auth_headers(user)
    { "Authorization" => "Bearer #{AuthTokenService.encode(user)}", "Content-Type" => "application/json" }
  end

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /admin/users" do
    it "returns 200 and lists all users for an admin" do
      other = create(:user)

      get "/admin/users", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      ids = json_body["users"].map { |user| user["id"] }
      expect(ids).to contain_exactly(admin.id, other.id)
    end

    it "returns 403 for a regular user" do
      get "/admin/users", headers: auth_headers(regular_user)

      expect(response).to have_http_status(:forbidden)
      expect(json_body["error"]).to eq("Forbidden")
    end

    it "returns 403 when no token is provided" do
      get "/admin/users"

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /admin/users/:id" do
    it "returns 200 with the user for an admin" do
      get "/admin/users/#{regular_user.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["user"]).to include("id" => regular_user.id, "role" => "user")
    end

    it "returns 403 for a regular user" do
      get "/admin/users/#{admin.id}", headers: auth_headers(regular_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 when the user does not exist" do
      get "/admin/users/999999", headers: auth_headers(admin)

      expect(response).to have_http_status(:not_found)
      expect(json_body["error"]).to eq("User not found")
    end
  end

  describe "PATCH /admin/users/:id/role" do
    it "updates the role when the value is valid" do
      patch "/admin/users/#{regular_user.id}/role",
            params: { role: "admin" }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_body["user"]["role"]).to eq("admin")
      expect(regular_user.reload.role).to eq("admin")
    end

    it "returns 422 for an invalid role value" do
      patch "/admin/users/#{regular_user.id}/role",
            params: { role: "superadmin" }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "role")).to be_present
      expect(regular_user.reload.role).to eq("user")
    end

    it "returns 422 for a blank role value" do
      patch "/admin/users/#{regular_user.id}/role",
            params: { role: "" }.to_json,
            headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("errors", "role")).to be_present
    end

    it "returns 403 for a regular user" do
      patch "/admin/users/#{admin.id}/role",
            params: { role: "user" }.to_json,
            headers: auth_headers(regular_user)

      expect(response).to have_http_status(:forbidden)
      expect(admin.reload.role).to eq("admin")
    end
  end
end
