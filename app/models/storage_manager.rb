class StorageManager

  attr_accessor :root_set, :draft_root, :medusa_root, :tmp_root

  def initialize

    storage_config = Rails.application.config_for(:medusa_storage)[:storage].collect(&:to_h)
    self.root_set = MedusaStorage::RootSet.new(storage_config)
    self.draft_root = self.root_set.at('draft')
    self.medusa_root = self.root_set.at('medusa')
    self.tmp_root = self.root_set.at('tmp')

  end

end