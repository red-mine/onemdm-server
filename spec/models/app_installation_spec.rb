require 'rails_helper'

RSpec.describe AppInstallation, type: :model do
  it { should belong_to(:device) }
  it { should belong_to(:app_batch_installation) }

  # Create AppInstallation Model [Device ID, app batch installation ID, status(Pushed, Downloaded, Cancelled, Installed)]
  describe "AppInstallation status" do
    let!(:AppInstallation){FactoryGirl.create(:app_installation)}
    it "Default status" do
      expect(app_installation.status).to eql AppInstallation.statuses.keys[0]
    end
    it "Pushed" do
      app_installation.pushed!
      expect(app_installation.status).to eql AppInstallation.statuses.keys[0]
    end
    it "Downloaded" do
      app_installation.downloaded!
      expect(app_installation.status).to eql AppInstallation.statuses.keys[1]
    end
    it "Cancelled" do
      app_installation.cancelled!
      expect(app_installation.status).to eql AppInstallation.statuses.keys[2]
    end

    it "Installed" do
      app_installation.installed!
      expect(app_installation.status).to eql AppInstallation.statuses.keys[3]
    end

  end

  describe "GCM Push " do
    let(:app_installation){FactoryGirl.build(:app_installation)}

    it "if status is pushed" do
      expect_any_instance_of(GCM).to receive(:send).and_return(app_installation)
      app_installation.save
    end
    it "status is not pushed" do
      expect_any_instance_of(GCM).not_to receive(:send)
      app_installation.cancelled!
    end
  end

end
