# app/admin/dashboard.rb
ActiveAdmin.register_page "Dashboard" do
  # Hide from the top navigation; keep the page available at /admin/dashboard
  menu false

  # Hide breadcrumb on the front page (provide an empty breadcrumb builder)
  breadcrumb do
    []
  end

  content title: "Deployments" do
    # === /Deployments Overview removed ===

    panel "All Deployments" do
      table_for Deployment.order(:name) do
        column(:id)
        column("Deployment Name", :name) { |dep| link_to dep.name, admin_deployment_path(dep) }
        column("Active Devices") { |dep| dep.active_devices_count }
        column("Install Percentages") do |dep|
          installed = dep.ota_installed_count
          offered   = dep.ota_offered_count
          pct       = dep.ota_install_percentage
          if offered.zero?
            span "–%"; br; small "(0 / 0)"
          else
            span "#{pct}%"; br; small "(#{installed} / #{offered})"
          end
        end
        column("Last update") { |dep| dep.ota_last_update_at || '-' }
        column(:actions) { |dep| link_to('View', admin_deployment_path(dep)) }
      end

      # New Deployment action intentionally hidden to keep creation restricted
    end

    # Device Status panel hidden on front page

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

    # Recent Pushes for OTA panel hidden on front page
  end
end
