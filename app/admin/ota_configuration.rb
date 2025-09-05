# frozen_string_literal: true
ActiveAdmin.register OtaConfiguration do
  # Hide global menu; access OTA Configurations from a Deployment's tabs
  menu false

  permit_params :deployment_id, :name, :description, :automatic_update, :in_production, :rollout_start_at,
                :rollout_strategy, :rollout_total_percent, :rollout_step_percent, :rollout_step_interval_hours,
                :rollout_current_percent, :paused, :pkg_id

  filter :deployment
  filter :name_cont, label: "Name contains"
  filter :automatic_update
  filter :in_production
  filter :created_at

  index do
    selectable_column
    id_column
    column(:name) { |c| link_to c.name, admin_ota_configuration_path(c) }
    column(:deployment) { |c| link_to c.deployment.name, admin_deployment_path(c.deployment) }
    column :automatic_update
    column(:pkg) { |c| c.pkg ? link_to(c.pkg.name, admin_pkg_path(c.pkg)) : status_tag('None', class: 'warning') }
    column :in_production
    column :rollout_start_at
    column("Targets") { |c| c.target_devices_count }
    column("Rollout") { |c| "#{c.rollout_progress}%" }
    column :created_at
    actions defaults: true do |c|
      item "Duplicate", duplicate_admin_ota_configuration_path(c), method: :post, class: "member_link"
      if c.rollout_strategy == 'staged'
        item "Advance", advance_rollout_admin_ota_configuration_path(c), method: :post, class: "member_link"
        if c.paused?
          item "Resume", resume_rollout_admin_ota_configuration_path(c), method: :post, class: "member_link"
        else
          item "Pause", pause_rollout_admin_ota_configuration_path(c), method: :post, class: "member_link"
        end
      end
    end
  end

  show title: :name do
    attributes_table do
      row :id
      row :deployment
      row :name
      row :description
      row :automatic_update
      row(:pkg) { |c| c.pkg ? link_to(c.pkg.name, admin_pkg_path(c.pkg)) : '-' }
      row :in_production
      row :rollout_start_at
      row :rollout_strategy
      row :rollout_total_percent
      row :rollout_step_percent
      row :rollout_step_interval_hours
      row :rollout_current_percent
      row("Targets") { resource.target_devices_count }
      row :paused
      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form do |f|
    f.inputs do
      f.input :deployment
      f.input :name
      f.input :description
      f.input :automatic_update
      f.input :in_production
      f.input :rollout_start_at, as: :datetime_select
    end

    # Groups removed: OTA Config targets all devices in the Deployment

    f.inputs "Staged Rollout" do
      f.input :rollout_strategy, as: :select, collection: [['Immediate', 'immediate'], ['Staged', 'staged']], include_blank: false
      f.input :rollout_total_percent
      f.input :rollout_step_percent
      f.input :rollout_step_interval_hours, label: 'Step interval (hours)'
      f.input :rollout_current_percent, hint: 'Current rollout progress (0-100)'
      f.input :paused
    end

    f.inputs "OTA Package" do
      pkgs = if f.object&.deployment_id
               f.object.deployment.ota_packages
             elsif params[:deployment_id]
               Deployment.find_by(id: params[:deployment_id])&.ota_packages || Pkg.all
             else
               Pkg.all
             end
      f.input :pkg, collection: pkgs, hint: 'Select the OTA package to roll out'
    end
    f.actions
  end

  # Duplicate action to quickly copy a configuration
  member_action :duplicate, method: :post do
    old = resource
    copy = old.duplicate!(new_name: params[:new_name])
    redirect_to admin_ota_configuration_path(copy), notice: "Configuration duplicated"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_ota_configuration_path(old), alert: e.record.errors.full_messages.to_sentence
  end

  member_action :advance_rollout, method: :post do
    resource.advance_rollout!
    redirect_to resource_path, notice: "Rollout advanced to #{resource.rollout_current_percent}%"
  rescue => e
    redirect_to resource_path, alert: e.message
  end

  member_action :pause_rollout, method: :post do
    resource.update!(paused: true)
    redirect_to resource_path, notice: 'Rollout paused'
  end

  member_action :resume_rollout, method: :post do
    resource.update!(paused: false)
    redirect_to resource_path, notice: 'Rollout resumed'
  end

  controller do
    def build_new_resource
      super.tap do |res|
        res.deployment_id ||= params[:deployment_id]
      end
    end
  end
end
