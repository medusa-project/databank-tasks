class CreateProblems < ActiveRecord::Migration[5.2]
  def change
    create_table :problems do |t|
      t.integer :task_id, limit: 8, null: false
      t.text :report, null: false
      t.string :status, default: 'reported'

      t.timestamps
    end
  end
end
