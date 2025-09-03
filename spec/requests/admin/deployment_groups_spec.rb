require 'rails_helper'

RSpec.describe 'Admin deployment groups', type: :request do
  let(:admin) { create(:admin_user, email: 'admin@example.com', password: 'password') }

  before do
    post admin_user_session_path, params: { admin_user: { email: admin.email, password: 'password' } }
  end

  it 'shows device groups for deployment' do
    deployment = create(:deployment, name: 'Main Deployment')
    group = create(:group, deployment: deployment, name: 'Group A', description: 'Test group')
    create(:device, deployment: deployment, group: group, unique_id: 'u1', gcm_token: 't1')

    get admin_deployment_path(deployment)

    expect(response.body).to include('Device Groups')
    expect(response.body).to include('Group A')
    expect(response.body).to include('Test group')
  end
end
