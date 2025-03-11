require 'rails_helper'

RSpec.describe Pkg, type: :model do

  let!(:pkg) { create(:pkg) }

  it { should validate_presence_of :name }
  it { should validate_presence_of :package_name }

  describe "OTA URL" do
    it "Default pkg" do
      pkg = create(:pkg)
      expect(pkg.pkg_url).to eql(DEFAULT_OTA_URL)
    end
    it "Non Default pkg" do
      pkg = Pkg.create(name: "Non MDM", package_name: "com.nonmdm")
      expect(pkg.ota_url).to eql("")
    end

  end
end
