ActiveAdmin.register Group do
  # Hide global Groups list; manage via Deployment tabs
  menu false

  permit_params :name, :deployment_id, :description

  index do
    selectable_column
    id_column
    column :name
    column :description
    column :deployment
    column :created_at
    column :updated_at
    actions
  end

  filter :name
  filter :deployment
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs "Group Details" do
      f.input :name
      f.input :description
      f.input :deployment
    end
    f.actions
  end

  action_item :back_to_deployment, only: [:show, :edit, :new] do
    dep = resource.deployment || Deployment.find_by(id: params[:deployment_id])
    link_to "Back to Deployment", admin_deployment_path(dep) if dep
  end

  show do
    attributes_table do
      row :name
      row :description
      row :deployment
      row :created_at
      row :updated_at
    end

    panel "Devices in this Group" do
      table_for group.devices do
        column :id
        column :model
        column :unique_id
        column :os_version
        column :client_version
        column :created_at
      end
    end
  end

  controller do
    def build_resource(*args)
      super.tap do |group|
        group.deployment_id ||= params[:deployment_id]
      end
    end
  end
end
