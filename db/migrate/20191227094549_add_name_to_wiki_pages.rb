class AddNameToWikiPages < ActiveRecord::Migration[5.2]
  def change
    add_column :wiki_pages, :name, :string, :default => "", :null => false
  end
end
