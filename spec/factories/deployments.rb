FactoryGirl.define do
  factory :deployment do
    sequence(:name) { |n| "Deployment #{n}" }
  end
end
