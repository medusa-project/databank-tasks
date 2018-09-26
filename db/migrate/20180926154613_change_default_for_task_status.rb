class ChangeDefaultForTaskStatus < ActiveRecord::Migration[5.2]
  def change
    change_column_default :tasks, :status, 'pending'
  end
end
