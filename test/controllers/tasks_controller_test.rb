require 'test_helper'

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
  end

  test "should get index" do
    get tasks_url, as: :json
    assert_response :success
  end

  test "should create task" do
    assert_difference('Task.count') do
      post tasks_url, params: { task: { binary_name: @task.binary_name, peek_text: @task.peek_text, peek_type: @task.peek_type, status: @task.status, storage_key: @task.storage_key, storage_root: @task.storage_root, web_id: @task.web_id } }, as: :json
    end

    assert_response 201
  end

  test "should show task" do
    get task_url(@task), as: :json
    assert_response :success
  end

  test "should update task" do
    patch task_url(@task), params: { task: { binary_name: @task.binary_name, peek_text: @task.peek_text, peek_type: @task.peek_type, status: @task.status, storage_key: @task.storage_key, storage_root: @task.storage_root, web_id: @task.web_id } }, as: :json
    assert_response 200
  end

  test "should destroy task" do
    assert_difference('Task.count', -1) do
      delete task_url(@task), as: :json
    end

    assert_response 204
  end
end
