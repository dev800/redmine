class AddKeywordsToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :keywords, :string, :default => '', :null => false
    add_column :users, :pinyin, :string, :default => '', :null => false
  end
end
