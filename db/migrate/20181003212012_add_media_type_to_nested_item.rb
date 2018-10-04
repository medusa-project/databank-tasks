class AddMediaTypeToNestedItem < ActiveRecord::Migration[5.2]
  def change
    add_column :nested_items, :media_type, :string
  end
end
