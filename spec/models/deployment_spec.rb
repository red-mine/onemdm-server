require 'rails_helper'

RSpec.describe Deployment, type: :model do
  subject { create(:deployment) }

  it { should have_many(:devices).dependent(:nullify) }
  it { should have_many(:groups).dependent(:nullify) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name) }
end
