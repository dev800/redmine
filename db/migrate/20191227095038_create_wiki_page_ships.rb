class CreateWikiPageShips < ActiveRecord::Migration[5.2]
  def change
    create_table :wiki_page_ships do |t|
      t.string :target_type, :default => "", :null => false
      t.integer :target_id, :default => 0, :null => false
      t.integer :wiki_page_id
      t.string :name, :default => "", :null => false
      t.integer :usage, :default => 0, :null => false
      t.integer :position, :default => 0, :null => false

      t.index [:wiki_page_id]
      t.index [:target_id, :target_type]
      t.index [:target_id, :target_type, :wiki_page_id], :unique => true, :name => :index_wiki_page_ships_on_target_and_wiki_page_id
    end
  end
end
