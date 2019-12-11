class AddCrossCollaborationToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :cross_collaboration, :boolean, :default => true, :null => false
  end
end
