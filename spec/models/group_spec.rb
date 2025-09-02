require 'rails_helper'

RSpec.describe Group, type: :model do
  it { should belong_to(:deployment).optional }
  it { should have_many(:devices) }
  it { should validate_presence_of(:name) }
end
