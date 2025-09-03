require 'rails_helper'

RSpec.describe 'Admin device group assignment', type: :request do
  let(:admin) { create(:admin_user, email: 'admin@example.com', password: 'password') }

  before do
    post admin_user_session_path, params: { admin_user: { email: admin.email, password: 'password' } }
  end

  it 'assigns selected devices to a group' do
    deployment = create(:deployment)
    group = create(:group, deployment: deployment, name: 'Group B')
    device = create(:device, deployment: deployment, unique_id: 'u1', gcm_token: 't1')

    post batch_action_admin_devices_path, params: {
      batch_action: 'assign_group',
      'Group Name' => group.id,
      collection_selection: [device.id]
    }

    expect(response).to redirect_to(admin_devices_path)
    expect(device.reload.group).to eq(group)
  end
end
