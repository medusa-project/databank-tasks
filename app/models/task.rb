class Task < ApplicationRecord

  has_many :problems, dependent: :destroy
  has_many :nested_items, dependent: :destroy

  def process
    begin
    # set status to processing
    # copy file from storage to temporary filesystem
    # extract features
    # delete file from temporary filesystem
    # set status to complete
    rescue StandardError => error
      raise("error handling not yet implemented")
    end
    raise("not yet implemented")
  end
end
