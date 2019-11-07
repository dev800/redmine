class CreateChecklists < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_statuses, :flag_color, :string, default: "ffffff", null: false
    add_column :issue_statuses, :background_color, :string, default: "ffffff", null: false
    add_column :issue_statuses, :flag_value, :string, null: false
    add_column :trackers, :flag_color, :string, default: "ffffff", null: false
    add_column :trackers, :background_color, :string, default: "ffffff", null: false
    add_column :trackers, :flag_value, :string, null: false

    create_table :checklists do |t|
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

    add_column :ar_internal_metadata, :deleted_at, :timestamp
    add_column :attachments, :deleted_at, :timestamp
    add_column :auth_sources, :deleted_at, :timestamp
    add_column :boards, :deleted_at, :timestamp
    add_column :changes, :deleted_at, :timestamp
    add_column :changeset_parents, :deleted_at, :timestamp
    add_column :changesets, :deleted_at, :timestamp
    add_column :changesets_issues, :deleted_at, :timestamp
    add_column :checklists, :deleted_at, :timestamp
    add_column :comments, :deleted_at, :timestamp
    add_column :custom_field_enumerations, :deleted_at, :timestamp
    add_column :custom_fields, :deleted_at, :timestamp
    add_column :custom_fields_projects, :deleted_at, :timestamp
    add_column :custom_fields_roles, :deleted_at, :timestamp
    add_column :custom_fields_trackers, :deleted_at, :timestamp
    add_column :custom_values, :deleted_at, :timestamp
    add_column :documents, :deleted_at, :timestamp
    add_column :email_addresses, :deleted_at, :timestamp
    add_column :enabled_modules, :deleted_at, :timestamp
    add_column :enumerations, :deleted_at, :timestamp
    add_column :groups_users, :deleted_at, :timestamp
    add_column :import_items, :deleted_at, :timestamp
    add_column :imports, :deleted_at, :timestamp
    add_column :issue_categories, :deleted_at, :timestamp
    add_column :issue_relations, :deleted_at, :timestamp
    add_column :issue_statuses, :deleted_at, :timestamp
    add_column :issues, :deleted_at, :timestamp
    add_column :journal_details, :deleted_at, :timestamp
    add_column :journals, :deleted_at, :timestamp
    add_column :member_roles, :deleted_at, :timestamp
    add_column :members, :deleted_at, :timestamp
    add_column :messages, :deleted_at, :timestamp
    add_column :news, :deleted_at, :timestamp
    add_column :open_id_authentication_associations, :deleted_at, :timestamp
    add_column :open_id_authentication_nonces, :deleted_at, :timestamp
    add_column :projects, :deleted_at, :timestamp
    add_column :projects_trackers, :deleted_at, :timestamp
    add_column :queries, :deleted_at, :timestamp
    add_column :queries_roles, :deleted_at, :timestamp
    add_column :repositories, :deleted_at, :timestamp
    add_column :roles, :deleted_at, :timestamp
    add_column :roles_managed_roles, :deleted_at, :timestamp
    add_column :schema_migrations, :deleted_at, :timestamp
    add_column :settings, :deleted_at, :timestamp
    add_column :time_entries, :deleted_at, :timestamp
    add_column :tokens, :deleted_at, :timestamp
    add_column :trackers, :deleted_at, :timestamp
    add_column :user_preferences, :deleted_at, :timestamp
    add_column :users, :deleted_at, :timestamp
    add_column :versions, :deleted_at, :timestamp
    add_column :watchers, :deleted_at, :timestamp
    add_column :wiki_content_versions, :deleted_at, :timestamp
    add_column :wiki_contents, :deleted_at, :timestamp
    add_column :wiki_pages, :deleted_at, :timestamp
    add_column :wiki_redirects, :deleted_at, :timestamp
    add_column :wikis, :deleted_at, :timestamp
    add_column :workflows, :deleted_at, :timestamp
  end
end
