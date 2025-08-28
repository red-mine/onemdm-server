ActiveAdmin.register Device do

  menu priority: 5, label: "Devices"

  # 允许的参数（保留原样）
  permit_params :model, :unique_id, :serial_no, :finger_print, :imei_number, :os_version, :client_version, :gcm_token, :group_id

  # ===== FingerPrint 解析（常量 + lambda，避免 helper_method） =====
  FP_REGEX = /\A
    (?<brand>[^\/]+)\/
    (?<product>[^\/]+)\/
    (?<device>[^:]+):
    (?<release>[^\/]+)\/
    (?<build_id>[^\/]+)\/
    (?<incremental>[^:]+):
    (?<build_type>[^\/]+)\/
    (?<tags>.+)
  \z/x.freeze

  PARSE_FP = ->(str) do
    return {} if str.blank?
    m = FP_REGEX.match(str)
    return {} unless m
    {
      brand:        m[:brand],
      product:      m[:product],
      device:       m[:device],
      release:      m[:release],
      build_id:     m[:build_id],
      incremental:  m[:incremental],
      build_type:   m[:build_type],
      tags:         m[:tags],
    }
  end

  # ===== 批量动作：保留你的原逻辑 =====
  app_data = lambda do
    apps = App.order('name').reload.pluck(:name,:id)
    {"App Name" => apps}
  end

  pkg_data = lambda do
    pkgs = Pkg.order('name').reload.pluck(:name,:id)
    {"Pkg Name" => pkgs}
  end

  group_data = lambda do
    groups = Group.order(:name).pluck(:name, :id)
    { "Group Name" => groups }
  end

  batch_action :push_apps, confirm: "Select apps to push", form: app_data do |ids, inputs|
    app = App.find(inputs["App Name"])
    batch = AppBatchInstallation.create(app: app)
    ids.each do | id |
      install = AppInstallation.new(device: Device.find(id), app_batch_installation: batch)
      install.pushed!
    end
    redirect_to admin_dashboard_path, notice: "Successfully pushed app to device(s)"
  end

  batch_action :push_pkgs, confirm: "Select pkgs to push", form: pkg_data do |ids, inputs|
    pkg = Pkg.find(inputs["Pkg Name"])
    batch = PkgBatchInstallation.create(pkg: pkg)
    ids.each do | id |
      install = PkgInstallation.new(device: Device.find(id), pkg_batch_installation: batch)
      install.pushed!
    end
    redirect_to admin_dashboard_path, notice: "Successfully pushed pkg to device(s)"
  end

  batch_action :assign_group, confirm: "Select Group to assign", form: group_data do |ids, inputs|
    group = Group.find(inputs["Group Name"])
    Device.where(id: ids).update_all(group_id: group.id)
    redirect_to collection_path, notice: "Devices successfully assigned to group #{group.name}"
  end

  # ===== 列表页：优先显示从 FP 解析的值 =====
  index do
    selectable_column
    id_column
    column "Status" do | device |
      status = device.status
      status_tag status.titleize, STATUS_CLASSES[status.to_sym]
    end
    column("Model Name") { |d| (pf = PARSE_FP.call(d.finger_print))[:device].presence  || d.model }
    # column "IMEI Number",:imei_number
    column :unique_id
    column :serial_no
    column :finger_print
    column("OS Version") { |d| (pf = PARSE_FP.call(d.finger_print))[:release].presence || d.os_version }
    column :client_version

    # 追加可视化构建信息（来自 FP，非必填）
    column("Build ID")    { |d| PARSE_FP.call(d.finger_print)[:build_id] }
    column("Incremental") { |d| PARSE_FP.call(d.finger_print)[:incremental] }
    column("Type/Tags")   { |d| pf = PARSE_FP.call(d.finger_print); [pf[:build_type], pf[:tags]].compact.join(" / ") }

    column :heartbeats_count
    column :last_heartbeat_recd_time
    column :created_at
    column "Group" do |device|
      device.group&.name
    end
    actions
  end

  # ===== 筛选器（保留原有 + 增加一个模糊搜索 FP 的输入框） =====
  filter :model
  filter :created_at
  filter :updated_at
  filter :last_heartbeat_recd_time
  filter :os_version
  filter :client_version
  filter :imei_number
  filter :group
  filter :finger_print_contains, as: :string, label: "FP contains"

  # ===== 状态 scope（保留原样） =====
  scope :active
  scope :missing
  scope :dead

  # ===== 表单（保留原样，增加提示） =====
  form do |f|
    f.inputs "Device Details" do
      f.input :model,        hint: "展示时优先读取指纹中的 device（此字段可作为兜底）"
      f.input :unique_id
      f.input :serial_no
      f.input :finger_print, hint: "格式：brand/product/device:release/id/incremental:type/tags"
      f.input :imei_number
      f.input :os_version,   hint: "展示时优先读取指纹中的 release（此字段可作为兜底）"
      f.input :client_version
      f.input :gcm_token
      f.input :group, as: :select, collection: Group.all.collect { |g| [g.name, g.id] }
    end
    f.actions
  end

  # ===== 详情页：增加 FP 解析展示（保留你的面板） =====
  show do
    attributes_table do
      row :model do |d|
        (pf = PARSE_FP.call(d.finger_print))[:device].presence || d.model
      end
      row :imei_number
      row :unique_id
      row :os_version do |d|
        (pf = PARSE_FP.call(d.finger_print))[:release].presence || d.os_version
      end
      row :client_version
      row :last_heartbeat_recd_time
      row :heartbeats_count
      row :created_at
      row :updated_at

      row "FingerPrint Parsed" do |d|
        pf = PARSE_FP.call(d.finger_print)
        if pf.blank?
          status_tag "Invalid FP", :warning
        else
          content_tag(:table, class: "index_table") do
            content_tag(:tbody) do
              [
                content_tag(:tr) { content_tag(:th, "Brand")       + content_tag(:td, pf[:brand]) },
                content_tag(:tr) { content_tag(:th, "Product")     + content_tag(:td, pf[:product]) },
                content_tag(:tr) { content_tag(:th, "Device")      + content_tag(:td, pf[:device]) },
                content_tag(:tr) { content_tag(:th, "OS Release")  + content_tag(:td, pf[:release]) },
                content_tag(:tr) { content_tag(:th, "Build ID")    + content_tag(:td, pf[:build_id]) },
                content_tag(:tr) { content_tag(:th, "Incremental") + content_tag(:td, pf[:incremental]) },
                content_tag(:tr) { content_tag(:th, "Build Type")  + content_tag(:td, pf[:build_type]) },
                content_tag(:tr) { content_tag(:th, "Tags")        + content_tag(:td, pf[:tags]) },
              ].join.html_safe
            end
          end
        end
      end

      # ====== 你原有的使用/安装面板（原样保留） ======
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
        table_for device.app_installations.order('updated_at desc') do
          column "App Name" do |app_installation|
            link_to app_installation.app.name, admin_app_path(app_installation.app.id)
          end
          column(:status){ |app_installation| app_installation.status.titleize }
          column "Date", :updated_at
        end
      end

      panel "OTA INSTALL DETAILS" do
        table_for device.pkg_installations.order('updated_at desc') do
          column "OTA Name" do |pkg_installation|
            link_to pkg_installation.pkg.name, admin_pkg_path(pkg_installation.pkg.id)
          end
          column(:status){ |pkg_installation| pkg_installation.status.titleize }
          column "Date", :updated_at
        end
      end
    end
  end

  # ===== CSV 导出：包含 FP 拆解字段 =====
  csv do
    column(:id)
    column(:unique_id)
    column(:serial_no)
    column(:finger_print)
    column("brand")       { |d| PARSE_FP.call(d.finger_print)[:brand] }
    column("product")     { |d| PARSE_FP.call(d.finger_print)[:product] }
    column("device")      { |d| PARSE_FP.call(d.finger_print)[:device] }
    column("os_release")  { |d| PARSE_FP.call(d.finger_print)[:release] }
    column("build_id")    { |d| PARSE_FP.call(d.finger_print)[:build_id] }
    column("incremental") { |d| PARSE_FP.call(d.finger_print)[:incremental] }
    column("build_type")  { |d| PARSE_FP.call(d.finger_print)[:build_type] }
    column("tags")        { |d| PARSE_FP.call(d.finger_print)[:tags] }
    column(:client_version)
    column(:heartbeats_count)
    column(:last_heartbeat_recd_time)
    column(:created_at)
    column("group") { |d| d.group&.name }
  end
end
