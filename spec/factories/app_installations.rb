FactoryGirl.define do
  factory :app_installation do
    association :device
    association :app_batch_installation
  end

end
