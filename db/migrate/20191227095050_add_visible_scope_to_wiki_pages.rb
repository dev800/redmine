class AddVisibleScopeToWikiPages < ActiveRecord::Migration[5.2]
  def change
    add_column :wiki_pages, :visile_scope, :string, :default => "project_members", :null => false
  end
end
