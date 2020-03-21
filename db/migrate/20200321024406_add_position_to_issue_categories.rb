class AddPositionToIssueCategories < ActiveRecord::Migration[5.2]
  def change
    add_column :issue_categories, :position, :integer, :default => 0, :null => false
  end
end
