# app/admin/pkgs.rb
ActiveAdmin.register Pkg do
  menu priority: 3, label: "OTA Packages"

  # 二选一：
  # - 用 ActiveStorage: 允许 :file
  # - 用外链字段     : 允许 :file_url
  permit_params :name, :finger_print, :file, :file_url

  controller do
    before_action { @page_title = "OTA Packages" }
  end

  # 列表页：Name 变成可下载链接
  index do
    selectable_column
    id_column

    column :name do |pkg|
      if pkg.respond_to?(:file) && pkg.file.respond_to?(:attached?) && pkg.file.attached?
        # ActiveStorage 附件下载链接
        link_to pkg.name, rails_blob_path(pkg.file, disposition: "attachment"), target: "_blank"
      elsif pkg.respond_to?(:file_url) && pkg.file_url.present?
        # 直接外链
        link_to pkg.name, pkg.file_url, target: "_blank"
      else
        pkg.name
      end
    end

    column :finger_print
    column :created_at
    column :updated_at

    actions defaults: true do |pkg|
      if pkg.respond_to?(:file) && pkg.file.respond_to?(:attached?) && pkg.file.attached?
        item "Download", rails_blob_path(pkg.file, disposition: "attachment"), class: "member_link", target: "_blank"
      elsif pkg.respond_to?(:file_url) && pkg.file_url.present?
        item "Download", pkg.file_url, class: "member_link", target: "_blank"
      end
    end
  end

  # 过滤器
  filter :name
  filter :finger_print
  filter :created_at
  filter :updated_at

  # 详情页：展示下载链接
  show do
    attributes_table do
      row :id
      row :name
      row :finger_print
      row :file do |pkg|
        if pkg.respond_to?(:file) && pkg.file.respond_to?(:attached?) && pkg.file.attached?
          link_to pkg.file.filename.to_s, rails_blob_path(pkg.file, disposition: "attachment"), target: "_blank"
        elsif pkg.respond_to?(:file_url) && pkg.file_url.present?
          link_to File.basename(pkg.file_url), pkg.file_url, target: "_blank"
        end
      end
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  # 表单：支持上传附件或填写外链
  form do |f|
    f.inputs "OTA Package Details" do
      f.input :name, label: "Package Name"
      f.input :finger_print, label: "Finger Print"

      if resource.respond_to?(:file) # ActiveStorage
        f.input :file, as: :file,
                hint: (resource.file.attached? ? link_to(resource.file.filename.to_s, rails_blob_path(resource.file, disposition: "attachment")) : nil)
      end

      if resource.respond_to?(:file_url)
        f.input :file_url, label: "File URL（可选：直接外链）"
      end
    end
    f.actions
  end
end
