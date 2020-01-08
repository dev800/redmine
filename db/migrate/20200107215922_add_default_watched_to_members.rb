class AddDefaultWatchedToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :default_watched, :boolean, :default => false, :null => false
  end
end
