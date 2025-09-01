# app/admin/pkgs.rb
ActiveAdmin.register Pkg do
  menu priority: 3, label: "OTA Packages"
  permit_params :name, :finger_print

  controller do
    before_action { @page_title = "OTA Packages" }
  end

  # 列表页：Name -> 下载链接 （优先 ota_url，其次内部 download 动作）
  index do
    selectable_column
    id_column

    column :name do |pkg|
      if pkg.ota_url.present?
        link_to pkg.name, pkg.ota_url, target: "_blank", rel: "noopener"
      elsif File.exist?(Rails.root.join("public", "ota", File.basename(pkg.name.to_s)))
        link_to pkg.name, download_admin_pkg_path(pkg)
      else
        pkg.name # 找不到可下载资源就显示纯文本
      end
    end

    column :finger_print
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

  # 过滤器
  filter :name
  filter :finger_print
  filter :created_at
  filter :updated_at

  # 详情页也放一个下载入口
  show do
    attributes_table do
      row :id
      row :name
      row :finger_print
      row :download do |pkg|
        if pkg.ota_url.present?
          link_to "Download", pkg.ota_url, target: "_blank", rel: "noopener"
        elsif File.exist?(Rails.root.join("public", "ota", File.basename(pkg.name.to_s)))
          link_to "Download", download_admin_pkg_path(pkg)
        end
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  # 受控下载：从 public/ota/<name> 发送文件
  member_action :download, method: :get do
    pkg = resource
    file_name = File.basename(pkg.name.to_s) # 防目录穿越
    path = Rails.root.join("public", "ota", file_name)

    if File.exist?(path)
      send_file path,
                filename: file_name,
                type: "application/zip",
                disposition: "attachment"
    else
      redirect_to resource_path, alert: "File not found: #{file_name}"
    end
  end
end
