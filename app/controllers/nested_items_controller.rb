class NestedItemsController < ApplicationController
  before_action :set_nested_item, only: [:show, :update, :destroy]

  # GET /nested_items
  def index
    @nested_items = NestedItem.all

    render json: @nested_items
  end

  # GET /nested_items/1
  def show
    render json: @nested_item
  end

  # POST /nested_items
  def create
    @nested_item = NestedItem.new(nested_item_params)

    if @nested_item.save
      render json: @nested_item, status: :created, location: @nested_item
    else
      render json: @nested_item.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /nested_items/1
  def update
    if @nested_item.update(nested_item_params)
      render json: @nested_item
    else
      render json: @nested_item.errors, status: :unprocessable_entity
    end
  end

  # DELETE /nested_items/1
  def destroy
    @nested_item.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nested_item
      @nested_item = NestedItem.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def nested_item_params
      params.require(:nested_item).permit(:task_id, :item_name, :item_path, :item_size, :is_directory)
    end
end
