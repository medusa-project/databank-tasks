class CreateNestedItems < ActiveRecord::Migration[5.2]
  def change
    create_table :nested_items do |t|
      t.integer :task_id, limit: 8, null: false
      t.string :item_name, null: false
      t.string :item_path, null: false
      t.integer :item_size, limit: 8, default: 0
      t.boolean :is_directory, default: false

      t.timestamps
    end
  end
end
