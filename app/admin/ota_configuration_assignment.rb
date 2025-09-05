# frozen_string_literal: true
ActiveAdmin.register OtaConfigurationAssignment do
  menu false

  permit_params :ota_configuration_id, :group_id

  actions :new, :create, :destroy, :index, :show

  # Keep index as a simple fallback/debug view
  index do
    selectable_column
    id_column
    column(:deployment) { |a| a.ota_configuration&.deployment }
    column(:ota_configuration)
    column(:group)
    column :created_at
    actions
  end

  show do
    attributes_table do
      row(:id)
      row(:deployment) { |a| a.ota_configuration&.deployment }
      row(:ota_configuration)
      row(:group)
      row(:created_at)
      row(:updated_at)
    end
  end

  form do |f|
    dep = if f.object&.ota_configuration&.deployment
            f.object.ota_configuration.deployment
          elsif params[:deployment_id]
            Deployment.find_by(id: params[:deployment_id])
          end

    cfgs = dep ? dep.ota_configurations.order(:name) : OtaConfiguration.all.order(:name)
    grps = dep ? dep.groups.order(:name) : Group.all.order(:name)

    f.inputs do
      f.input :ota_configuration, collection: cfgs, include_blank: false
      f.input :group, collection: grps, include_blank: false
    end
    f.actions
  end

  controller do
    def build_new_resource
      super.tap do |res|
        # If a deployment was provided, try to preselect the only available option when unique
        if params[:deployment_id].present?
          dep = Deployment.find_by(id: params[:deployment_id])
          if dep
            res.ota_configuration ||= dep.ota_configurations.first if dep.ota_configurations.one?
            res.group ||= dep.groups.first if dep.groups.one?
          end
        end
      end
    end

    def create
      super do |success, failure|
        success.html do
          redirect_back fallback_location: admin_ota_configuration_assignment_path(resource),
                        notice: 'Assignment created'
        end
        failure.html { render :new }
      end
    end
  end
end

