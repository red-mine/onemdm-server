# app/admin/pkgs.rb
ActiveAdmin.register Pkg do
  # Hide global OTA Packages list; access via Deployment > OTA Packages
  menu false
  permit_params :name, :finger_print
  
  # 允许从 Deployment/Dashboard 带参跳转做模糊过滤
  filter :finger_print_cont, label: 'Fingerprint contains'
  filter :name_cont

  controller do
    before_action { @page_title = "OTA Packages" }

    def destroy
      pkg = resource
      if OtaConfiguration.where(pkg_id: pkg.id).exists?
        redirect_to resource_path, alert: "Cannot delete: used by one or more OTA configurations. Remove those links first."
        return
      end
      super
    rescue ActiveRecord::InvalidForeignKey
      redirect_to resource_path, alert: "Cannot delete: package is referenced by OTA configurations."
    end
  end

  # 列表页：Name -> 下载链接（优先 ota_url，其次内部 download 动作）
  index do
    selectable_column
    id_column

    column :name do |pkg|
      if pkg.ota_url.present?
        link_to pkg.name, pkg.ota_url, target: "_blank", rel: "noopener"
      elsif File.exist?(Rails.root.join("public", "ota", File.basename(pkg.name.to_s)))
        link_to pkg.name, download_admin_pkg_path(pkg)
      else
        pkg.name # 找不到资源显示纯文本
      end
    end

    # ✅ 只显示 Deployment 名称，不显示完整指纹
    column "Deployment" do |pkg|
      parts = [pkg.fp_brand, pkg.fp_device, pkg.fp_product].compact
      parts.any? ? parts.join("_").downcase : "-"
    end

    # 保留一些关键的解析字段（可按需精简/调整顺序）
    column("OS Release")  { |pkg| pkg.fp_os_release }
    column("Build ID")    { |pkg| pkg.fp_build_id }
    column("Incremental") { |pkg| pkg.fp_incremental }
    column("Type")        { |pkg| pkg.fp_build_type }

    column :created_at
    column :updated_at

    actions defaults: true do |pkg|
      if pkg.ota_url.present?
        item "Download", pkg.ota_url, class: "member_link", target: "_blank", rel: "noopener"
      elsif File.exist?(Rails.root.join("public", "ota", File.basename(pkg.name.to_s)))
        item "Download", download_admin_pkg_path(pkg), class: "member_link"
      end
    end
  end

  # 过滤器（指纹可用包含搜索）
  filter :name
  filter :finger_print_cont, label: "finger_print contains"
  filter :created_at
  filter :updated_at

  # 详情页：基本信息 + Fingerprint 解析 + 下载入口
  show do
    attributes_table do
      row :id
      row :name
      row :finger_print
      row :created_at
      row :updated_at
      row :download do |pkg|
        if pkg.ota_url.present?
          link_to "Download", pkg.ota_url, target: "_blank", rel: "noopener"
        elsif File.exist?(Rails.root.join("public", "ota", File.basename(pkg.name.to_s)))
          link_to "Download", download_admin_pkg_path(pkg)
        end
      end
    end

    panel "Fingerprint Parsed" do
      pf = resource.parsed_fingerprint
      if pf.blank?
        div class: "blank_slate_container" do
          span "Cannot parse finger_print with the standard Android format."
        end
      else
        attributes_table_for resource do
          row("Brand")       { pf[:brand] }
          row("Product")     { pf[:product] }
          row("Device")      { pf[:device] }
          row("OS Release")  { pf[:os_release] }
          row("Build ID")    { pf[:build_id] }
          row("Incremental") { pf[:incremental] }
          row("Build Type")  { pf[:build_type] }
          row("Tags")        { pf[:tags] }
        end
      end
    end

    active_admin_comments
  end

  # 受控下载：从 public/ota/<name> 发送文件
  member_action :download, method: :get do
    pkg = resource
    file_name = File.basename(pkg.name.to_s) # 防目录穿越
    base_dir  = Rails.root.join("public", "ota")
    path      = base_dir.join(file_name)

    # 额外白名单检查
    unless path.to_s.start_with?(base_dir.to_s)
      redirect_to resource_path, alert: "Invalid file path"
      return
    end

    if File.exist?(path)
      # 使用 marcel 自动识别 MIME（Rails 默认依赖）
      mime = Marcel::MimeType.for(path)
      send_file path,
                filename: file_name,
                type: mime,
                disposition: "attachment"
    else
      redirect_to resource_path, alert: "File not found: #{file_name}"
    end
  end
end
