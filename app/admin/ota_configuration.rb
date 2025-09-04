# frozen_string_literal: true
ActiveAdmin.register OtaConfiguration do
  menu parent: "Deployments", priority: 5, label: "OTA Configurations"

  permit_params :deployment_id, :name, :description, :automatic_update, :in_production, :rollout_start_at

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
    column :in_production
    column :rollout_start_at
    column :created_at
    actions defaults: true do |c|
      item "Duplicate", duplicate_admin_ota_configuration_path(c), method: :post, class: "member_link"
    end
  end

  show title: :name do
    attributes_table do
      row :id
      row :deployment
      row :name
      row :description
      row :automatic_update
      row :in_production
      row :rollout_start_at
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

  controller do
    def build_new_resource
      super.tap do |res|
        res.deployment_id ||= params[:deployment_id]
      end
    end
  end
end
