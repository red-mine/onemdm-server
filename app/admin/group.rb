ActiveAdmin.register Group do
  menu priority: 4, label: "Groups"

  permit_params :name, :development, :description

  index do
    selectable_column
    id_column
    column :name
    column :description
    column :development
    column :created_at
    column :updated_at
    actions
  end

  filter :name
  filter :development
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs "Group Details" do
      f.input :name
      f.input :description
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :description
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
end
