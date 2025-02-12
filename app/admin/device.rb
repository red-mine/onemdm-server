ActiveAdmin.register Device do

  actions :all, except: [:edit,:new]

  app_data = lambda do
    apps = App.order('name').reload.pluck(:name,:id)
    {"App Name" => apps}
  end

  batch_action :push, confirm: "Select apps to push",form: app_data do |ids,inputs|
    app = App.find(inputs["App Name"])
    batch = BatchInstallation.create(:app => app)
    ids.each do | id |
      install = Installation.new(device: Device.find(id),batch_installation: batch)
      install.pushed!
    end
    redirect_to admin_dashboard_path, notice: "Successfully pushed app to device(s)"
  end

  index do
    selectable_column
    id_column
    column "Status" do | device |
      status = device.status
      status_tag status.titleize, STATUS_CLASSES[status.to_sym]
    end
    column "Model Name",:model
    column "IMEI Number",:imei_number
    column :os_version
    column :client_version
    column :heartbeats_count
    column :last_heartbeat_recd_time
    column :created_at
    actions
  end
  filter :model
  filter :created_at
  filter :updated_at
  filter :last_heartbeat_recd_time
  filter :os_version
  filter :client_version
  filter :imei_number

  scope :active
  scope :missing
  scope :dead

  show do
    attributes_table do
      row :model
      row :imei_number
      row :unique_id
      row :os_version
      row :client_version
      row :last_heartbeat_recd_time
      row :heartbeats_count
      row :created_at
      row :updated_at
      total_usage = 0

      panel "App Usage Details" do
        table_for device.app_usage_summary do
          column "Used On" do |app_usage|
            app_usage[:used_on]
          end
          column "App Name" do |app_usage|
            app_usage[:package_name]
          end
          column "Total Usage" do |app_usage|
            total_usage += app_usage[:usage]
            distance_of_time_in_words app_usage[:usage]
          end
        end
      end

      row "Total Usage" do
        distance_of_time_in_words total_usage
      end

      panel "APP INSTALL DETAILS" do
        table_for device.installations.order('updated_at desc') do
          column "App Name" do |installation|
            link_to installation.app.name, admin_app_path(installation.app.id)
          end
          column(:status){ |installation| installation.status.titleize }
          column "Date", :updated_at
        end
      end
    end
  end
end
