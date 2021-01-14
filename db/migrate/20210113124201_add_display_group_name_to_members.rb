class AddDisplayGroupNameToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :display_group_name, :string, :default => '', :null => false
  end
end
