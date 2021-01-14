class AddMemberGroupedToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :member_grouped, :boolean, :default => false, :null => false
  end
end
