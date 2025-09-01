# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # === Developments (brand_product_device from fingerprint) ===
    panel "Developments" do
      # 用局部变量避免常量重复定义警告
      fp_regex = /\A
        (?<brand>[^\/]+)\/
        (?<product>[^\/]+)\/
        (?<device>[^:]+):
        (?<release>[^\/]+)\/
        (?<build_id>[^\/]+)\/
        (?<incremental>[^:]+):
        (?<build_type>[^\/]+)\/
        (?<tags>.+)
      \z/x

      # 解析器用 lambda，避免在类级别定义方法
      parse_deployment = lambda do |fp, fallback_model = nil|
        m = fp_regex.match(fp.to_s)
        unless m
          name = fallback_model.presence || "(unknown)"
          return [name, nil]
        end
        name   = "#{m[:brand]}_#{m[:product]}_#{m[:device]}".downcase
        prefix = "#{m[:brand]}/#{m[:product]}/#{m[:device]}:"
        [name, prefix]
      end

      # 取必要字段避免 N+1
      devs = Device.select(:id, :finger_print, :model, :updated_at)

      # 分组：deployment_name => { :prefix, :devices => [Device,...] }
      groups = Hash.new { |h, k| h[k] = { prefix: nil, devices: [] } }
      devs.each do |d|
        name, prefix = parse_deployment.call(d.finger_print, d.model)
        groups[name][:prefix] ||= prefix
        groups[name][:devices] << d
      end

      names = groups.keys.sort

      table_for names do
        # Deployment 名称（点击按 fingerprint 前缀筛选）
        column("Deployment Name") do |name|
          prefix = groups[name][:prefix]
          if prefix.present?
            link_to name, admin_devices_path(q: { finger_print_cont: prefix })
          else
            name
          end
        end

        # Active Devices（如有 scope :active，可替换为 Device.where(id: ids).active.count）
        column("Active Devices") do |name|
          groups[name][:devices].size
        end

        # 安装率（Installed / Offered）：以该部署设备参与的最近一次 OTA 批次计算
        column("Install Percentages (Installed / Offered)") do |name|
          ids = groups[name][:devices].map(&:id)   # ← 不要用 map!，避免把设备数组改成整数
          latest = PkgBatchInstallation
                     .joins(:pkg_installations)
                     .where(pkg_installations: { device_id: ids })
                     .order(id: :desc)
                     .first

          if latest
            scope = latest.pkg_installations.where(device_id: ids)
            offered   = scope.count
            installed = scope.where(status: PkgInstallation.statuses[:installed]).count
            pct = offered.zero? ? 0.0 : (installed.to_f / offered * 100.0)
            "#{number_to_percentage(pct, precision: 1)} (#{installed} / #{offered})"
          else
            "–% (– / –)"
          end
        end

        # 最近更新时间：该部署下设备的最大 updated_at
        column("Last update") do |name|
          ts = groups[name][:devices].map(&:updated_at).compact.max
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
