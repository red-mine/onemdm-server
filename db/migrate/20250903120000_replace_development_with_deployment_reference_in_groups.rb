class ReplaceDevelopmentWithDeploymentReferenceInGroups < ActiveRecord::Migration[7.0]
  def change
    remove_column :groups, :development, :string
    add_reference :groups, :deployment, foreign_key: true, index: true
  end
end
