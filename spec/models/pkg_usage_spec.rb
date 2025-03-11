require 'rails_helper'

RSpec.describe PkgUsage, type: :model do
  let!(:pkg_usage) { create(:pkg_usage) }

  it { should validate_presence_of :package_name }
  it { should validate_presence_of :usage_duration_in_seconds }
  it { should validate_presence_of :used_on }
  it { should belong_to :device }

  context "Pkg Usage report" do
    let!(:pkg_usage) { create(:pkg_usage, device_id: nil) }
    it "Ignore Deleted devices" do
      pkg_usage = PkgUsage.pkg_usages_per_device_pkg_day
      expect(pkg_usage).to be_empty
    end

  end
end
