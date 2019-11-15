class CreateChecklists < ActiveRecord::Migration[5.2]
  def change
    create_table :checklists do |t|
      # 重要度
      t.integer :importance, default: 1, :null => false
      # 排序值
      t.integer :position, default: 0, :limit => 8
      # 问题ID
      t.integer :issue_id
      # 跟踪类型
      t.integer :tracker_id, null: false
      # 项目ID
      t.integer :project_id, null: false
      # 主题
      t.string :subject, default: "", null: false
      # 详情
      t.text :description
      # 预计时间
      t.date :due_date
      # 分类ID
      t.integer :category_id
      # 状态ID
      t.integer :status_id, null: false
      # 指派给谁的id
      t.integer :assigned_to_id
      # 优先级
      t.integer :priority_id, null: false
      # 修复的版本id
      t.integer :fixed_version_id
      # 作者ID
      t.integer :author_id, null: false
      # 版本号
      t.integer :lock_version, default: 0, null: false
      # 开始日期
      t.date :start_date
      # 完成度
      t.integer :done_ratio, default: 0, null: false
      # 预计工时
      t.float :estimated_hours
      t.integer :parent_id
      t.integer :root_id
      t.integer :lft
      t.integer :rgt
      # 是否私有
      t.boolean :is_private, default: false, null: false
      # 关闭时间
      t.datetime :closed_on

      t.datetime :created_on
      t.datetime :updated_on

      t.index [:position]
      t.index [:issue_id]
      t.index [:assigned_to_id]
      t.index [:author_id]
      t.index [:category_id]
      t.index [:created_on]
      t.index [:fixed_version_id]
      t.index [:parent_id]
      t.index [:priority_id]
      t.index [:project_id]
      t.index [:root_id, :lft, :rgt]
      t.index [:status_id]
      t.index [:tracker_id]
    end
  end
end
