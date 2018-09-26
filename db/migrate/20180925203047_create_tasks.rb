class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :web_id
      t.string :storage_root
      t.string :storage_key
      t.string :binary_name
      t.string :status
      t.string :peek_type
      t.text :peek_text

      t.timestamps
    end
  end
end
