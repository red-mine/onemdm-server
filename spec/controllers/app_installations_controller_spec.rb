require 'rails_helper'

RSpec.describe AppInstallationsController, type: :controller do
  let(:app_installation) {FactoryGirl.create(:app_installation)}
  let(:device){app_installation.device}
  context "With Authentication" do
    before(:each)do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(device.access_token)
    end

    it "POST #installed" do
      post :installed, :id => app_installation.id  , format: :json
      expect(response).to have_http_status(:ok)
      expect(AppInstallation.last.installed?).to be true
    end
  end

  context "Require Authentication" do
    it "POST #installed" do
      post :installed, :id => app_installation.id  , format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
