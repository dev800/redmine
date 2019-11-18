class CreateMemberRoles < ActiveRecord::Migration[4.2]
  def self.up
    create_table :member_roles do |t|
      t.column :member_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
      t.column :deleted_at, :timestamp
    end
  end

  def self.down
    drop_table :member_roles
  end
end
