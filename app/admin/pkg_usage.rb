ActiveAdmin.register_page "Pkg Usage" do

  # Hide global OTA Usage; use per-deployment flows instead
  menu false

  content title: "OTA Usage" do
    pkg_usage_data = []
    begin
      pkg_usages = PkgUsage.pkg_usages_per_device_pkg_day
      pkg_usages.each do |key,value|
        pkg_usage_data << {device_id: key[0],
                        finger_print: key[1],
                        used_on: key[2],
                        usage: value}
      end
    rescue

    end

    panel "Usage Report" do
      table_for pkg_usage_data do
        column "Used On" do |pkg_usage|
          pkg_usage[:used_on]
        end
        column "Device" do |pkg_usage|
          device_id = pkg_usage[:device_id]
          link_to device_id, admin_device_path(device_id)
        end
        column "Package Name" do |pkg_usage|
          pkg_usage[:finger_print]
        end
        column "Total Usage" do |pkg_usage|
          distance_of_time_in_words (pkg_usage[:usage])
        end
      end
    end
  end # content
end
