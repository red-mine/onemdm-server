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
      tab "OTA Packages" do
        dep = resource
        sample_fp = dep.devices.where.not(finger_print: [nil, ""]).limit(1).pluck(:finger_print).first
        short = sample_fp.to_s.split(":", 2).first.presence
        if short
          div do
            text_node link_to "Open filtered OTA Packages (#{short})",
                               admin_pkgs_path(q: { finger_print_cont: short }),
                               class: "button"
          end
        else
          status_tag "No sample fingerprint", :warning
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
