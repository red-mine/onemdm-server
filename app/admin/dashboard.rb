# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # === Deployments（基于新表）的快速入口 ===
    panel "Deployments (new)" do
      deployments = Deployment.order(:name).select(:id, :name)

      table_for deployments do
        column "DEPLOYMENT NAME" do |dep|
          show_link = link_to dep.name, admin_deployment_path(dep)

          sample_fp = Device.where(deployment_id: dep.id)
                            .where.not(finger_print: [nil, ""])
                            .limit(1).pluck(:finger_print).first
          short = sample_fp.to_s.split(":", 2).first.presence

          if short
            ota_link = link_to "📦 OTA",
                              admin_pkgs_path(q: { finger_print_cont: short }),
                              class: "btn btn-small",
                              title: "View OTA Packages for #{dep.name}"
            safe_join([show_link, " ", ota_link])
          else
            show_link
          end
        end

        column "ACTIVE DEVICES" do |dep|
          Device.where(deployment_id: dep.id)
                .where.not(last_heartbeat_recd_time: nil).count
        end

        column "OTA PACKAGES" do |dep|
          short = Device.where(deployment_id: dep.id)
                        .where.not(finger_print: [nil, ""])
                        .limit(1).pluck(:finger_print).first.to_s.split(":", 2).first.presence
          short ? link_to("View", admin_pkgs_path(q: { finger_print_cont: short })) : status_tag("N/A")
        end

        column "LAST UPDATE" do |dep|
          Device.where(deployment_id: dep.id).maximum(:updated_at)
        end
      end
    end
    # === /Deployments ===

    panel "Device Status" do
      columns do
        STATUS_CLASSES.keys.each do |status|
          column span: 1 do
            span status.to_s.titleize
            span link_to(Device.send(status).count, admin_devices_path(scope: status.to_s))
          end
        end
      end
    end

    # panel "Recent Pushes for App" do
    #   table_for AppBatchInstallation.order('id desc').limit(10) do
    #     column("Pushed on", &:created_at)
    #     column("App Name") { |batch| batch.app.name }
    #     column("# Devices")   { |b| link_to b.app_installations.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id }) }
    #     column("# Installed") { |b| link_to b.app_installations.installed.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_eq: AppInstallation.statuses[:installed] }) }
    #     column("# Cancelled") { |b| link_to b.app_installations.cancelled.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_eq: AppInstallation.statuses[:cancelled] }) }
    #     column("# Pending")   { |b| link_to(b.app_installations.pushed.count + b.app_installations.downloaded.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_in: [AppInstallation.statuses[:pushed], AppInstallation.statuses[:downloaded]] })) }
    #     column "% Success" do |b|
    #       total = b.app_installations.count
    #       installed = b.app_installations.installed.count
    #       pct = total.zero? ? 0.0 : (installed.to_f / total * 100.0)
    #       number_to_percentage(pct, precision: 1)
    #     end
    #   end
    # end

    panel "Recent Pushes for OTA" do
      table_for PkgBatchInstallation.order('id desc').limit(10) do
        column("Pushed on", &:created_at)
        column("OTA Name") { |batch| batch.pkg.name }
        column("# Devices")   { |b| link_to b.pkg_installations.count, admin_devices_path(q: { pkg_installations_pkg_batch_installation_id_eq: b.id }) }
        column("# Installed") { |b| link_to b.pkg_installations.installed.count, admin_devices_path(q: { pkg_installations_pkg_batch_installation_id_eq: b.id, installations_status_eq: PkgInstallation.statuses[:installed] }) }
        column("# Cancelled") { |b| link_to b.pkg_installations.cancelled.count, admin_devices_path(q: { pkg_installations_pkg_batch_installation_id_eq: b.id, installations_status_eq: PkgInstallation.statuses[:cancelled] }) }
        column("# Pending")   { |b| link_to(b.pkg_installations.pushed.count + b.pkg_installations.downloaded.count, admin_devices_path(q: { pkg_installations_pkg_batch_installation_id_eq: b.id, installations_status_in: [PkgInstallation.statuses[:pushed], PkgInstallation.statuses[:downloaded]] })) }
        column "% Success" do |b|
          total = b.pkg_installations.count
          installed = b.pkg_installations.installed.count
          pct = total.zero? ? 0.0 : (installed.to_f / total * 100.0)
          number_to_percentage(pct, precision: 1)
        end
      end
    end
  end
end
