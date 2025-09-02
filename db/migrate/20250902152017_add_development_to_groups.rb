class AddDevelopmentToGroups < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :development, :string
    add_index  :groups, :development
  end
end
