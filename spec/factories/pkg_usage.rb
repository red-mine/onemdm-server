FactoryGirl.define do
  factory :pkg_usage do
    finger_print "com.facebook.katana"
    usage_duration_in_seconds 7000
    used_on Date.today - 1.day
  end
  factory :invalid_pkg_usage, class: PkgUsage do
    finger_print ""
    usage_duration_in_seconds 7000
    used_on Date.today - 1.day
  end

end
