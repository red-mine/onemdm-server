ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # === New: Developments panel (像 GOTA 的列表) ===
    panel "Developments" do
      # 以 Device.model 作为 Deployment Name
      models = Device.distinct.order(:model).pluck(:model)

      table_for models do
        # Deployment 名称 -> 点进去筛选该型号设备
        column("Deployment Name") { |m| link_to(m.presence || "(unknown)", admin_devices_path(q: { model_eq: m })) }

        # 活跃设备数量（若你有 scope :active，可替换为 Device.active）
        column("Active Devices")  { |m| Device.where(model: m).count }

        # 安装百分比（Installed / Offered）基于该型号最近一次 OTA 批次
        column("Install Percentages (Installed / Offered)") do |m|
          latest = PkgBatchInstallation
                     .joins(pkg_installations: :device)
                     .where(devices: { model: m })
                     .order(id: :desc)
                     .first

          if latest
            offered   = latest.pkg_installations.joins(:device).where(devices: { model: m }).count
            installed = latest.pkg_installations
                               .joins(:device)
                               .where(devices: { model: m }, status: PkgInstallation.statuses[:installed])
                               .count
            pct = offered.zero? ? 0.0 : (installed.to_f / offered * 100.0)
            "#{number_to_percentage(pct, precision: 1)} (#{installed} / #{offered})"
          else
            "–% (– / –)"
          end
        end

        # 最近一次相关 OTA 批次的时间
        column("Last update") do |m|
          ts = PkgBatchInstallation
                 .joins(pkg_installations: :device)
                 .where(devices: { model: m })
                 .maximum(:created_at)
          ts ? l(ts, format: :long) : "—"
        end
      end
    end
    # === /Developments ===

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

    panel "Recent Pushes for App" do
      table_for AppBatchInstallation.order('id desc').limit(10) do
        column("Pushed on", &:created_at)
        column("App Name") { |batch| batch.app.name }
        column("# Devices")   { |b| link_to b.app_installations.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id }) }
        column("# Installed") { |b| link_to b.app_installations.installed.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_eq: AppInstallation.statuses[:installed] }) }
        column("# Cancelled") { |b| link_to b.app_installations.cancelled.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_eq: AppInstallation.statuses[:cancelled] }) }
        column("# Pending")   { |b| link_to(b.app_installations.pushed.count + b.app_installations.downloaded.count, admin_devices_path(q: { app_installations_app_batch_installation_id_eq: b.id, installations_status_in: [AppInstallation.statuses[:pushed], AppInstallation.statuses[:downloaded]] })) }
        column "% Success" do |b|
          total = b.app_installations.count
          installed = b.app_installations.installed.count
          pct = total.zero? ? 0.0 : (installed.to_f / total * 100.0)
          number_to_percentage(pct, precision: 1)
        end
      end
    end

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
