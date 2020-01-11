class AddSomeColumnsForSeo < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :seo_title, :string, :default => "", :null => false
    add_column :projects, :seo_keywords, :string, :default => "", :null => false
    add_column :projects, :seo_description, :string, :default => "", :null => false
  end
end
