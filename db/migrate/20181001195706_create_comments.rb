class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.integer :problem_id, limit: 8, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
