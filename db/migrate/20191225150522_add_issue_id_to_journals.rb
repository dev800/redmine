class AddIssueIdToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :journals, :issue_id, :integer, :default => true
    add_column :journals, :checklist_id, :integer, :default => true
    add_index :journals, [:issue_id]
    add_index :journals, [:checklist_id]
  end
end
