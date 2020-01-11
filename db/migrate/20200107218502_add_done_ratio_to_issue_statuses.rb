class AddDoneRatioToIssueStatuses < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_statuses, :done_ratio, :integer, :default => 0, :null => false
    add_column :issue_statuses, :done_ratio_changed, :boolean, :default => false, :null => false
  end

  def up
    Issue.find_each(&:save)
    Checklist.find(&:save)
  end
end
