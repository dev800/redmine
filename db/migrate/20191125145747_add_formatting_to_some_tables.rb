class AddFormattingToSomeTables < ActiveRecord::Migration[5.2]
  def change
    add_column :issues, :formatting, :string, :default => 'markdown', :null => false
    add_column :checklists, :formatting, :string, :default => 'markdown', :null => false
    add_column :documents, :formatting, :string, :default => 'markdown', :null => false
    add_column :news, :formatting, :string, :default => 'markdown', :null => false
    add_column :projects, :formatting, :string, :default => 'markdown', :null => false
    add_column :custom_fields, :formatting, :string, :default => 'markdown', :null => false
  end
end
