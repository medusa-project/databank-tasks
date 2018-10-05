APP_CONFIG = YAML.load_file(ERB.new(File.join(Rails.root, 'config', 'app.yml')))

Application.storage_manager = StorageManager.new
