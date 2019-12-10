class CreateParticipants < ActiveRecord::Migration[5.2]
  def change
    create_table :participants do |t|
      t.string :partable_type, :default => "", :null => false
      t.integer :partable_id, :default => 0, :null => false
      # 对应人
      t.integer :user_id
      # 是否是负责人
      t.boolean :is_leader, :default => false, :null => false
      # 是否是需求方
      t.boolean :is_requester, :default => false, :null => false
      # 是否是解决者
      t.boolean :is_resolver, :default => false, :null => false
      # 是否是测试员
      t.boolean :is_tester, :default => false, :null => false
      # 是否是跟踪者
      t.boolean :is_tracker, :default => false, :null => false

      t.index [:user_id, :partable_type]
      t.index [:user_id]
      t.index [:partable_id, :partable_type]
      t.index [:partable_id, :partable_type, :user_id], :unique => true
    end
  end
end
