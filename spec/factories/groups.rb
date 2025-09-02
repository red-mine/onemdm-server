FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    association :deployment
  end
end
