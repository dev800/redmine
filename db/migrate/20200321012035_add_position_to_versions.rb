class AddPositionToVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :position, :integer, :default => 0, :null => false
  end
end
