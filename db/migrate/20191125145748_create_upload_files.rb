class CreateUploadFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :upload_files do |t|
      t.string :filename, default: "", null: false
      t.string :disk_filename, default: "", null: false
      t.bigint :filesize, default: 0, null: false
      t.string :content_type, default: ""
      t.string :digest, limit: 64, default: "", null: false
      t.integer :downloads, default: 0, null: false
      t.integer :author_id, default: 0, null: false
      t.datetime :created_on
      t.datetime :deleted_at
      t.string :description
      t.string :disk_directory
      t.string :secret

      t.index [:author_id]
      t.index [:created_on]
      t.index [:disk_filename]
    end
  end
end
