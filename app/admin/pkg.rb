ActiveAdmin.register Pkg do
  menu priority: 3, label: "OTA Packages"

  permit_params :name, :finger_print

  controller do
    before_action { @page_title = "OTA Packages" }
  end

  # 自定义列表页
  index do
    selectable_column
    id_column
    column :name
    column :finger_print
    column :created_at
    column :updated_at
    actions
  end

  # 搜索条件
  filter :name
  filter :finger_print
  filter :created_at
  filter :updated_at

  # 表单
  form do |f|
    f.inputs "OTA Package Details" do
      f.input :name, label: "Package Name"
      f.input :finger_print, label: "Finger Print"
    end
    f.actions
  end
end
