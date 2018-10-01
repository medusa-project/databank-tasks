require 'test_helper'

class NestedItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nested_item = nested_items(:one)
  end

  test "should get index" do
    get nested_items_url, as: :json
    assert_response :success
  end

  test "should create nested_item" do
    assert_difference('NestedItem.count') do
      post nested_items_url, params: { nested_item: { is_directory: @nested_item.is_directory, item_name: @nested_item.item_name, item_path: @nested_item.item_path, item_size: @nested_item.item_size, task_id: @nested_item.task_id } }, as: :json
    end

    assert_response 201
  end

  test "should show nested_item" do
    get nested_item_url(@nested_item), as: :json
    assert_response :success
  end

  test "should update nested_item" do
    patch nested_item_url(@nested_item), params: { nested_item: { is_directory: @nested_item.is_directory, item_name: @nested_item.item_name, item_path: @nested_item.item_path, item_size: @nested_item.item_size, task_id: @nested_item.task_id } }, as: :json
    assert_response 200
  end

  test "should destroy nested_item" do
    assert_difference('NestedItem.count', -1) do
      delete nested_item_url(@nested_item), as: :json
    end

    assert_response 204
  end
end
