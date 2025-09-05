# frozen_string_literal: true
ActiveAdmin.register Deployment do
  # Hide global Deployments list; navigate from Dashboard instead
  menu false

  # Quick navigation back to the dashboard from a deployment page
  action_item :back_to_dashboard, only: :show do
    link_to 'Back to Dashboard', admin_dashboard_path
  end

  # Provide a low‑profile entry point to create a new deployment
  # while keeping "New" hidden from the combined Deployments page.
  action_item :new_deployment, only: :show do
    link_to 'New Deployment', new_admin_deployment_path
  end

  permit_params :name, :description, :build_prefix, :build_suffix, :partner_product_id

  filter :name_cont, label: "Name contains"
  filter :partner_product_id_cont, label: "Partner Product ID"
  filter :build_prefix_cont
  filter :build_suffix_cont

  index title: "Your Deployments" do
    selectable_column
    id_column
    column("Deployment Name", :name) { |dep| link_to dep.name, admin_deployment_path(dep) }
    column("Active Devices") { |dep| dep.active_devices_count }
    column("Install Percentages") do |dep|
      installed = dep.ota_installed_count
      offered = dep.ota_offered_count
      pct = dep.ota_install_percentage
      if offered.zero?
        span "–%"
        br
        small "(0 / 0)"
      else
        span "#{pct}%"
        br
        small "(#{installed} / #{offered})"
      end
    end
    column("Last update") do |dep|
      dep.ota_last_update_at || '-'
    end
    actions
  end

  show title: :name do
    # Render details more compactly: two columns inside one panel
    panel "Deployment Details" do
      # Single row table with labeled columns to fit one line
      table_for [resource] do
        column("Name") { |dep| dep.name }
        column("Description") { |dep| dep.description.presence || status_tag('empty', type: :warning) }
        column("Partner Product") { |dep| dep.partner_product_id.presence || status_tag('empty', type: :warning) }
        column("Build Prefix") { |dep| dep.build_prefix.presence || status_tag('empty', type: :warning) }
        column("Build Suffix") { |dep| dep.build_suffix.presence || status_tag('empty', type: :warning) }
        column("Active Devices") { |dep| dep.devices.where.not(last_heartbeat_recd_time: nil).count }
        column("Created At") { |dep| dep.created_at }
        column("Updated At") { |dep| dep.updated_at }
      end
    end

    tabs do
      # Preferred order: Assignments → Device Groups → OTA Configurations → OTA Packages → Devices
      tab "Assignments" do
        assignments = OtaConfigurationAssignment
                        .includes(:ota_configuration, :group)
                        .joins(:ota_configuration)
                        .where(ota_configurations: { deployment_id: resource.id })

        if assignments.exists?
          table_for assignments do
            column(:group) { |a| link_to a.group.name, admin_group_path(a.group) }
            column(:ota_configuration) { |a| link_to a.ota_configuration.name, admin_ota_configuration_path(a.ota_configuration) }
            column :created_at
            column(:actions) do |a|
              links = []
              links << link_to('Delete', admin_ota_configuration_assignment_path(a), method: :delete,
                                data: { confirm: 'Remove this assignment?' })
              safe_join(links, ' | '.html_safe)
            end
          end
        else
          status_tag 'No assignments yet', type: :warning
        end

        div do
          link_to 'New Assignment', new_admin_ota_configuration_assignment_path(deployment_id: resource.id), class: 'button'
        end
      end

      tab "Device Groups" do
        table_for resource.groups do
          column(:name) { |g| link_to g.name, admin_group_path(g) }
          column :description
          column("Devices") { |g| g.devices.count }
        end

        div do
          link_to "Create Group for this Deployment", new_admin_group_path(deployment_id: resource.id), class: "button"
        end
      end

      tab "OTA Configurations" do
        table_for resource.ota_configurations.order(:name) do
          column(:name) { |cfg| link_to cfg.name, admin_ota_configuration_path(cfg) }
          column :automatic_update
          column :in_production
          column :rollout_start_at
          column(:pkg) { |cfg| cfg.pkg ? link_to(cfg.pkg.name, admin_pkg_path(cfg.pkg)) : '-' }
          column("Strategy") { |cfg| cfg.rollout_strategy }
          column("Targets") { |cfg| cfg.target_devices_count }
          column("Rollout") { |cfg| "#{cfg.rollout_progress}%" }
          column(:actions) do |cfg|
            span link_to("View", admin_ota_configuration_path(cfg))
            span " | "
            span link_to("Edit", edit_admin_ota_configuration_path(cfg))
            span " | "
            span link_to("Duplicate", duplicate_admin_ota_configuration_path(cfg), method: :post)
          end
        end

        div do
          link_to "Add Configuration", new_admin_ota_configuration_path(deployment_id: resource.id), class: "button"
        end
      end

      tab "OTA Packages" do
        pkgs = resource.ota_packages
        if pkgs.exists?
          table_for pkgs do
            column(:name) { |pkg| link_to pkg.name, admin_pkg_path(pkg) }
            column :finger_print
            column :created_at
          end
        else
          status_tag "No OTA packages found", type: :warning
        end

        div do
          link_to "Create OTA Package for this Deployment",
                  new_admin_pkg_path(deployment_id: resource.id),
                  class: "button"
        end
      end

      # Devices tab removed as requested; device details are accessible via other flows
    end
  end
end
