# frozen_string_literal: true
ActiveAdmin.register Deployment do
  menu priority: 2, label: "Deployments"

  permit_params :name, :description, :build_prefix, :build_suffix, :partner_product_id

  filter :name_cont, label: "Name contains"
  filter :partner_product_id_cont, label: "Partner Product ID"
  filter :build_prefix_cont
  filter :build_suffix_cont

  index do
    selectable_column
    id_column
    column(:name) { |dep| link_to dep.name, admin_deployment_path(dep) }
    column :partner_product_id
    column :build_prefix
    column :build_suffix
    column("Devices") { |dep| dep.devices.count }
    actions
  end

  show title: :name do
    attributes_table do
      row :name
      row :description
      row :partner_product_id
      row :build_prefix
      row :build_suffix
      row("Active devices") { |dep| dep.devices.where.not(last_heartbeat_recd_time: nil).count }
      row :created_at
      row :updated_at
    end

    tabs do
      tab "OTA Configurations" do
        table_for resource.ota_configurations.order(:name) do
          column(:name) { |cfg| link_to cfg.name, admin_ota_configuration_path(cfg) }
          column :automatic_update
          column :in_production
          column :rollout_start_at
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
          status_tag "No OTA packages found", :warning
        end

        div do
          link_to "Create OTA Package for this Deployment",
                  new_admin_pkg_path(deployment_id: resource.id),
                  class: "button"
        end
      end

      tab "Devices" do
        table_for resource.devices.order(id: :desc).limit(50) do
          column :id
          column :model
          column :unique_id
          column :serial_no
          column :os_version
          column :client_version
          column :last_heartbeat_recd_time
          column(:show) { |d| link_to "View", admin_device_path(d) }
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
    end
  end
end
