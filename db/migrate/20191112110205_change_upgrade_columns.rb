class ChangeUpgradeColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :importance, :integer, :default => 1, :null => false
    add_column :issues, :agile_visible, :boolean, :default => true, :null => false
    add_column :issues, :agile_position, :integer, :default => 0, :null => false
    add_column :issues, :liable_id, :integer

    add_column :issue_statuses, :agile_status, :integer, :default => 0, :null => false
    add_column :issue_statuses, :agile_color, :string, default: "000000", null: false
    add_column :issue_statuses, :agile_background_color, :string, default: "ffffff", null: false

    add_column :roles, :checklists_visibility, :string, :limit => 30, :default => 'default', :null => false

    add_column :time_entries, :checklist_id, :integer
    add_index :time_entries, [:checklist_id], :name => :time_entries_checklist_id

    add_column :enumerations, :flag_color, :string, default: "ffffff", null: false
    add_column :enumerations, :color, :string, default: "000000", null: false
    add_column :enumerations, :background_color, :string, default: "ffffff", null: false
    add_column :enumerations, :flag_value, :string, null: false

    add_column :issue_statuses, :flag_color, :string, default: "ffffff", null: false
    add_column :issue_statuses, :color, :string, default: "000000", null: false
    add_column :issue_statuses, :background_color, :string, default: "ffffff", null: false
    add_column :issue_statuses, :flag_value, :string, null: false

    add_column :trackers, :flag_color, :string, default: "ffffff", null: false
    add_column :trackers, :color, :string, default: "000000", null: false
    add_column :trackers, :background_color, :string, default: "ffffff", null: false
    add_column :trackers, :flag_value, :string, null: false

    add_column :ar_internal_metadata, :deleted_at, :timestamp
    # add_column :attachments, :deleted_at, :timestamp
    add_column :auth_sources, :deleted_at, :timestamp
    add_column :boards, :deleted_at, :timestamp
    add_column :changes, :deleted_at, :timestamp
    add_column :changeset_parents, :deleted_at, :timestamp
    # add_column :changesets, :deleted_at, :timestamp
    add_column :changesets_issues, :deleted_at, :timestamp
    add_column :checklists, :deleted_at, :timestamp
    add_column :comments, :deleted_at, :timestamp
    add_column :custom_field_enumerations, :deleted_at, :timestamp
    # add_column :custom_fields, :deleted_at, :timestamp
    add_column :custom_fields_projects, :deleted_at, :timestamp
    add_column :custom_fields_roles, :deleted_at, :timestamp
    add_column :custom_fields_trackers, :deleted_at, :timestamp
    # add_column :custom_values, :deleted_at, :timestamp
    add_column :documents, :deleted_at, :timestamp
    add_column :email_addresses, :deleted_at, :timestamp
    add_column :enabled_modules, :deleted_at, :timestamp
    # add_column :enumerations, :deleted_at, :timestamp
    add_column :groups_users, :deleted_at, :timestamp
    add_column :import_items, :deleted_at, :timestamp
    add_column :imports, :deleted_at, :timestamp
    add_column :issue_categories, :deleted_at, :timestamp
    add_column :issue_relations, :deleted_at, :timestamp
    # add_column :issue_statuses, :deleted_at, :timestamp
    # add_column :issues, :deleted_at, :timestamp
    # add_column :journal_details, :deleted_at, :timestamp
    add_column :journals, :deleted_at, :timestamp
    # add_column :member_roles, :deleted_at, :timestamp
    # add_column :members, :deleted_at, :timestamp
    # add_column :messages, :deleted_at, :timestamp
    add_column :news, :deleted_at, :timestamp
    add_column :open_id_authentication_associations, :deleted_at, :timestamp
    add_column :open_id_authentication_nonces, :deleted_at, :timestamp
    # add_column :projects, :deleted_at, :timestamp
    add_column :projects_trackers, :deleted_at, :timestamp
    add_column :queries, :deleted_at, :timestamp
    add_column :queries_roles, :deleted_at, :timestamp
    add_column :repositories, :deleted_at, :timestamp
    # add_column :roles, :deleted_at, :timestamp
    add_column :roles_managed_roles, :deleted_at, :timestamp
    add_column :schema_migrations, :deleted_at, :timestamp
    # add_column :settings, :deleted_at, :timestamp
    # add_column :time_entries, :deleted_at, :timestamp
    # add_column :tokens, :deleted_at, :timestamp
    # add_column :trackers, :deleted_at, :timestamp
    add_column :user_preferences, :deleted_at, :timestamp
    # add_column :users, :deleted_at, :timestamp
    add_column :versions, :deleted_at, :timestamp
    add_column :watchers, :deleted_at, :timestamp
    add_column :wiki_content_versions, :deleted_at, :timestamp
    add_column :wiki_contents, :deleted_at, :timestamp
    add_column :wiki_pages, :deleted_at, :timestamp
    # add_column :wiki_redirects, :deleted_at, :timestamp
    add_column :wikis, :deleted_at, :timestamp
    # add_column :workflows, :deleted_at, :timestamp
  end
end
