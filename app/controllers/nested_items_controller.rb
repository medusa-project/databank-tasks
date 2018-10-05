class NestedItemsController < ApplicationController
  before_action :set_nested_item, only: [:show]

  # GET /tasks/task_id/nested_items
  def index

    if params.has_key?(:task_id)

      @nested_items = NestedItem.where(task_id: params[:task_id])

      render json: @nested_items
    else
      render json: {error: 'missing task id'}, status: :unprocessable_entity
    end

  end

  # GET tasks/task_id/nested_items/1
  def show
    render json: @nested_item
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nested_item
      @nested_item = NestedItem.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def nested_item_params
      params.require(:nested_item).permit(:task_id)
    end
end
