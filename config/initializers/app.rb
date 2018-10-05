APP_CONFIG = YAML.load_file(ERB.new(File.read(File.join(Rails.root, 'config', 'app.yml'))).result)

Application.storage_manager = StorageManager.new
