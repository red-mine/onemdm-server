# app/admin/devices.rb
ActiveAdmin.register Device do
  menu priority: 5, label: "Devices"

  # 允许的参数（保留原样）
  permit_params :model, :unique_id, :deployment_id, :serial_no, :finger_print, :imei_number, :os_version, :client_version, :gcm_token, :group_id

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

  # 每次请求级别的简易缓存，避免重复解析指纹
  FP_CACHE = ->(fp) do
    @__fp_cache ||= {}
    @__fp_cache[fp] ||= PARSE_FP.call(fp)
  end

  # ===== 批量动作：保留你的原逻辑（加事务 + 预取） =====
  app_data = lambda do
    apps = App.order('name').reload.pluck(:name, :id)
    { "App Name" => apps }
  end

  pkg_data = lambda do
    pkgs = Pkg.order('name').reload.pluck(:name, :id)
    { "Pkg Name" => pkgs }
  end

  group_data = lambda do
    # Show distinct group names; assignment will resolve to the
    # device's own deployment group with the same name.
    dep_id = params.dig(:q, :deployment_id_eq)
    names = if dep_id.present?
              Group.where(deployment_id: dep_id).order(:name).distinct.pluck(:name)
            else
              Group.order(:name).distinct.pluck(:name)
            end
    { "Group Name" => names }
  end

  batch_action :push_apps, confirm: "Select apps to push", form: app_data do |ids, inputs|
    app = App.find(inputs["App Name"])
    ActiveRecord::Base.transaction do
      batch = AppBatchInstallation.create!(app: app)
      Device.where(id: ids).find_each do |device|
        AppInstallation.create!(device: device, app_batch_installation: batch, status: :pushed)
      end
    end
    redirect_to admin_dashboard_path, notice: "Successfully pushed app to #{ids.size} device(s)"
  end

  batch_action :push_pkgs, confirm: "Select pkgs to push", form: pkg_data do |ids, inputs|
    pkg = Pkg.find(inputs["Pkg Name"])
    ActiveRecord::Base.transaction do
      batch = PkgBatchInstallation.create!(pkg: pkg)
      Device.where(id: ids).find_each do |device|
        PkgInstallation.create!(device: device, pkg_batch_installation: batch, status: :pushed)
      end
    end
    redirect_to admin_dashboard_path, notice: "Successfully pushed pkg to #{ids.size} device(s)"
  end

  batch_action :assign_group, confirm: "Select Group to assign", form: group_data do |ids, inputs|
    group_name = inputs["Group Name"].presence
    unless group_name
      redirect_to collection_path, alert: "Please select a group name." and next
    end

    updated = 0
    skipped = 0
    Device.where(id: ids).find_each do |device|
      next unless device.deployment_id.present?
      target = Group.find_by(name: group_name, deployment_id: device.deployment_id)
      if target
        device.update_columns(group_id: target.id, updated_at: Time.current)
        updated += 1
      else
        skipped += 1
      end
    end

    msg = "Assigned #{updated} device(s) to '#{group_name}' within their deployments"
    msg += "; skipped #{skipped} with no matching group" if skipped > 0
    redirect_to collection_path, notice: msg
  end

  index do
    selectable_column
    id_column

    column "Status" do |device|
      status = device.status
      status_tag status.to_s.titleize, STATUS_CLASSES[status.to_sym]
    end

    column :unique_id
    column :serial_no

    # —— 自定义开发代号 —— 
    column "Deployment" do |d|
      pf = FP_CACHE.call(d.finger_print)
      parts = []
      parts << pf[:brand].to_s.downcase if pf[:brand].present?
      parts << pf[:device].to_s.downcase if pf[:device].present?
      parts << pf[:product].to_s.downcase if pf[:product].present?
      parts.reject!(&:blank?)
      parts.join("_").presence || "n/a"
    end

    # 保留其他字段（缩短列标题）
    column("OS")      { |d| FP_CACHE.call(d.finger_print)[:release].presence || d.os_version }
    column("Client")  { |d| d.client_version }
    column("HBs")     { |d| d.heartbeats_count }
    column("Last Heartbeat") { |d| d.last_heartbeat_recd_time }
    column("Created") { |d| d.created_at }
    column("Group") { |d| d.group&.name }

    actions
  end

  # ===== 筛选器（保留原有 + 模糊搜索 FP） =====
  filter :model
  filter :created_at
  filter :updated_at
  filter :last_heartbeat_recd_time
  filter :os_version
  filter :client_version
  filter :imei_number
  filter :group
  filter :deployment
  # Ransack 的 contains 谓词是 _cont
  filter :finger_print_cont, as: :string, label: "FP contains"

  # ===== Sidebar helper note =====
  sidebar "Batch Tips", only: :index do
    para "Choose a group name — each device is assigned to a group with the same name in its own deployment. " \
         "When you open ‘Assign Group Selected’, the list shows only names assignable to all selected devices. " \
         "If none are available, refine your selection or filter by Deployment."
  end

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

      # Only show groups belonging to the device's deployment
      groups_for_dep = []
      dep_id_for_form = f.object&.deployment_id
      if dep_id_for_form.present?
        groups_for_dep = Group.where(deployment_id: dep_id_for_form).order(:name).pluck(:name, :id)
      else
        groups_for_dep = []
      end
      f.input :group, as: :select, collection: groups_for_dep, include_blank: "None (same deployment only)"
    end
    f.actions
  end

  # ===== 详情页：增加 FP 解析展示（保留你的面板） =====
  show do
    attributes_table do
      row :model do |d|
        (pf = FP_CACHE.call(d.finger_print))[:device].presence || d.model
      end
      row :imei_number
      row :unique_id
      row :os_version do |d|
        (pf = FP_CACHE.call(d.finger_print))[:release].presence || d.os_version
      end
      row :client_version
      row :last_heartbeat_recd_time
      row :heartbeats_count
      row :created_at
      row :updated_at
      row :group

      row "FingerPrint Parsed" do |d|
        pf = FP_CACHE.call(d.finger_print)
        if pf.blank?
          status_tag "Invalid FP", type: :warning
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
          column("Used On")      { |u| u[:used_on] }
          column("App Name")     { |u| u[:package_name] }
          column("Total Usage")  do |u|
            total_usage += u[:usage]
            distance_of_time_in_words u[:usage]
          end
        end
      end

      row("Total Usage") { distance_of_time_in_words total_usage }

      panel "APP INSTALL DETAILS" do
        table_for device.app_installations.order(updated_at: :desc) do
          column("App Name") { |ai| link_to ai.app.name, admin_app_path(ai.app.id) }
          column(:status)    { |ai| ai.status.titleize }
          column "Date", :updated_at
        end
      end

      panel "OTA INSTALL DETAILS" do
        table_for device.pkg_installations.order(updated_at: :desc) do
          column("OTA Name") { |pi| link_to pi.pkg.name, admin_pkg_path(pi.pkg.id) }
          column(:status)    { |pi| pi.status.titleize }
          column "Date", :updated_at
        end
      end
    end
  end

  # ===== CSV 导出：包含 FP 拆解字段（使用缓存） =====
  csv do
    column(:id)
    column(:unique_id)
    column(:serial_no)
    column(:finger_print)
    column("brand")       { |d| FP_CACHE.call(d.finger_print)[:brand] }
    column("product")     { |d| FP_CACHE.call(d.finger_print)[:product] }
    column("device")      { |d| FP_CACHE.call(d.finger_print)[:device] }
    column("os_release")  { |d| FP_CACHE.call(d.finger_print)[:release] }
    column("build_id")    { |d| FP_CACHE.call(d.finger_print)[:build_id] }
    column("incremental") { |d| FP_CACHE.call(d.finger_print)[:incremental] }
    column("build_type")  { |d| FP_CACHE.call(d.finger_print)[:build_type] }
    column("tags")        { |d| FP_CACHE.call(d.finger_print)[:tags] }
    column(:client_version)
    column(:heartbeats_count)
    column(:last_heartbeat_recd_time)
    column(:created_at)
    column("group") { |d| d.group&.name }
  end

  # JSON endpoint used by admin JS to populate assignable groups
  # based on the currently selected device IDs. It returns the
  # intersection of group names across the selected devices' deployments.
  collection_action :assignable_group_names, method: :post do
    ids = Array(params[:ids]).map(&:to_s)
    deployments = Device.where(id: ids).distinct.pluck(:deployment_id).compact
    names = []
    if deployments.present?
      pairs = Group.where(deployment_id: deployments).pluck(:deployment_id, :name)
      names_by_dep = pairs.group_by { |d, _| d }.transform_values { |arr| arr.map { |_, n| n }.uniq }
      names = names_by_dep.values.reduce(nil) { |acc, arr| acc ? (acc & arr) : arr } || []
      names = names.sort
    end
    render json: { names: names }
  end
end
