ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    panel "Device Status"  do
      columns  do
        STATUS_CLASSES.keys.each do |status|
          column span:1 do
            span status.to_s.titleize
            span link_to(Device.send(status).count,
              admin_devices_path(scope: status.to_s))
          end
        end
      end
    end

    panel "Recent Pushes for App" do
      table_for AppBatchInstallation.order('id desc').limit(10) do
        column "Pushed on" do |batch|
          batch.created_at
        end
        column "App Name" do |batch|
          batch.app.name
        end
        column "# Devices" do |batch|
          link_to batch.app_installations.count,
            admin_devices_path(q: {app_installations_app_batch_installation_id_eq: batch.id})
        end
        column "# Installed" do |batch|
          link_to batch.app_installations.installed.count,
            admin_devices_path(q: {app_installations_app_batch_installation_id_eq: batch.id,
                                 installations_status_eq: AppInstallation.statuses[:installed]})
        end
        column "# Cancelled" do |batch|
          link_to batch.app_installations.cancelled.count,
            admin_devices_path(q: {app_installations_app_batch_installation_id_eq: batch.id,
                                 installations_status_eq: AppInstallation.statuses[:cancelled]})
        end
        column "# Pending" do |batch|
          link_to batch.app_installations.pushed.count + batch.app_installations.downloaded.count,
             admin_devices_path(q: {app_installations_app_batch_installation_id_eq: batch.id,
                                 installations_status_in: [AppInstallation.statuses[:pushed],
                                                           AppInstallation.statuses[:downloaded]]})
        end
        column "% Success" do |batch|
          total = batch.app_installations.count
          installed = batch.app_installations.installed.count
          percentage_success = (installed/total) * 100 if total > 0
        end
      end
    end

    panel "Recent Pushes for OTA" do
      table_for PkgBatchInstallation.order('id desc').limit(10) do
        column "Pushed on" do |batch|
          batch.created_at
        end
        column "OTA Name" do |batch|
          batch.pkg.name
        end
        column "# Devices" do |batch|
          link_to batch.pkg_installations.count,
            admin_devices_path(q: {pkg_installations_pkg_batch_installation_id_eq: batch.id})
        end
        column "# Installed" do |batch|
          link_to batch.pkg_installations.installed.count,
            admin_devices_path(q: {pkg_installations_pkg_batch_installation_id_eq: batch.id,
                                 installations_status_eq: PkgInstallation.statuses[:installed]})
        end
        column "# Cancelled" do |batch|
          link_to batch.pkg_installations.cancelled.count,
            admin_devices_path(q: {pkg_installations_pkg_batch_installation_id_eq: batch.id,
                                 installations_status_eq: PkgInstallation.statuses[:cancelled]})
        end
        column "# Pending" do |batch|
          link_to batch.pkg_installations.pushed.count + batch.pkg_installations.downloaded.count,
             admin_devices_path(q: {pkg_installations_pkg_batch_installation_id_eq: batch.id,
                                 installations_status_in: [PkgInstallation.statuses[:pushed],
                                                           PkgInstallation.statuses[:downloaded]]})
        end
        column "% Success" do |batch|
          total = batch.pkg_installations.count
          installed = batch.pkg_installations.installed.count
          percentage_success = (installed/total) * 100 if total > 0
        end
      end
    end

  end # content
end
