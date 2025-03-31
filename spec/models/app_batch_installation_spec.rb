require 'rails_helper'

RSpec.describe AppBatchInstallation, type: :model do
  it {should belong_to(:app)}
end
