require "rails_helper"

RSpec.describe "Authorization", type: :controller do
  controller(ApplicationController) do
    before_action :require_admin!, only: :index

    def index
      render json: { message: "ok" }, status: :ok
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  def auth_header(user)
    { "Authorization" => "Bearer #{AuthTokenService.encode(user)}" }
  end

  it "returns 403 when no token is provided" do
    get :index

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body)).to eq("error" => "Forbidden")
  end

  it "returns 403 when the authenticated user is not an admin" do
    user = create(:user, role: :user)
    request.headers.merge!(auth_header(user))

    get :index

    expect(response).to have_http_status(:forbidden)
  end

  it "allows the request through when the authenticated user is an admin" do
    admin = create(:user, role: :admin)
    request.headers.merge!(auth_header(admin))

    get :index

    expect(response).to have_http_status(:ok)
  end
end
