require 'mime/types'
require 'os'
require 'zip'
require 'libarchive'
require 'zlib'

class Task < ApplicationRecord

  has_many :problems, dependent: :destroy
  has_many :nested_items, dependent: :destroy

  ALLOWED_CHAR_NUM = 1024 * 8
  ALLOWED_DISPLAY_BYTES = ALLOWED_CHAR_NUM * 8
  TMP_ROOT = Application.storage_manager.tmp_root

  def self.tasks_from_params(params)

    if params.has_key?('status')

      # case: both elements filter and status filter
      if params.has_key?('elements')
        return Task.where(status: params['status']).pluck(params['elements'])

        # case: status filter, but no elements filter
      else
        return Task.where(status: params['status'])
      end

      # case: elements filter, but no status filter
    elsif params.has_key?('elements')
      return Task.pluck(params['elements'])
    else
      return Task.all
    end

  end

  def process
    begin
      self.status = TaskStatus::PROCESSING
      puts("Processing #{self.binary_name} for Task #{self.id}...")
      source_root = Application.storage_manager.root_set.at(self.storage_root)
      next unless source_root.exist?(self.storage_key)

      TMP_ROOT.copy_content_to(tmp_key, source_root, self.storage_key)
      features_extracted = extract_features
      if features_extracted
        self.status = TaskStatus::RIPE
      else
        self.status = TaskStatus::ERROR
      end
    rescue StandardError => error
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      report_problem(error.message)
      #raise error
    ensure
      if TMP_ROOT.exist?(tmp_tree_key)
        TMP_ROOT.delete_tree(tmp_tree_key)
      end
      if self.peek_text && self.peek_text.encoding.name != 'UTF-8'
        begin
          self.peek_text.encode('UTF-8')
          self.save
        rescue Encoding::UndefinedConversionError
          self.peek_text = nil
          self.peek_type = PeekType::NONE
          report_problem('invalid encoding for peek text')
        rescue Exception => ex
          report_problem("invalid encoding and problem characer: #{ex.class}, #{ex.message}")
        end
      else
        begin
          self.save
        rescue Exception => ex
          report_problem("problem saving task: #{ex.class}, #{ex.message}")
        end
      end
    end
  end

  def tmp_tree_key
    "task_#{self.id}"
  end

  def tmp_key
    Rails.logger.warn("self.tmp_tree_key: #{self.tmp_tree_key}")
    Rails.logger.warn("self.binary_name: #{self.binary_name}")
    File.join(self.tmp_tree_key, self.binary_name)
  end

  def report_problem(report)
    Problem.create(task_id: self.id, report: report)
  end

  def extract_features

    if self.binary_name.last(6) == 'txt.gz'
      return extract_txtgz
    end

    mime_guess = top_level_mime || mime_from_filename(self.binary_name) || 'application/octet-stream'

    #Rails.logger.warn("#{self.binary_name} - #{mime_guess}")

    mime_parts = mime_guess.split("/")

    text_subtypes = ['csv', 'xml', 'x-sh', 'x-javascript', 'json', 'r', 'rb']

    nonzip_archive_subtypes = ['x-7z-compressed', 'x-tar']

    pdf_subtypes = ['pdf', 'x-pdf']

    microsoft_subtypes = ['msword',
                          'vnd.openxmlformats-officedocument.wordprocessingml.document',
                          'vnd.openxmlformats-officedocument.wordprocessingml.template',
                          'vnd.ms-word.document.macroEnabled.12',
                          'vnd.ms-word.template.macroEnabled.12',
                          'vnd.ms-excel',
                          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                          'vnd.openxmlformats-officedocument.spreadsheetml.template',
                          'vnd.ms-excel.sheet.macroEnabled.12',
                          'vnd.ms-excel.template.macroEnabled.12',
                          'vnd.ms-excel.addin.macroEnabled.12',
                          'vnd.ms-excel.sheet.binary.macroEnabled.12',
                          'vnd.ms-powerpoint',
                          'vnd.openxmlformats-officedocument.presentationml.presentation',
                          'vnd.openxmlformats-officedocument.presentationml.template',
                          'vnd.openxmlformats-officedocument.presentationml.slideshow',
                          'vnd.ms-powerpoint.addin.macroEnabled.12',
                          'vnd.ms-powerpoint.presentation.macroEnabled.12',
                          'vnd.ms-powerpoint.template.macroEnabled.12',
                          'vnd.ms-powerpoint.slideshow.macroEnabled.12']

    subtype = mime_parts[1].downcase

    if mime_parts[0] == 'text' || text_subtypes.include?(subtype)
      return extract_text
    elsif mime_parts[0] == 'image'
      return extract_image
    elsif microsoft_subtypes.include?(subtype)
      return extract_microsoft
    elsif pdf_subtypes.include?(subtype)
      return extract_pdf
    elsif subtype == 'zip'
      return extract_zip
    elsif nonzip_archive_subtypes.include?(subtype)
      return extract_archive
    else
      return extract_default
    end

  end

  def storage_path
    # this works because the tmp root is always a filesystem
    root_path = Application.storage_manager.tmp_root.path
    File.join(root_path, self.tmp_key)
  end

  def top_level_mime
    Task.mime_from_path(self.storage_path)
  end

  def self.mime_from_path(path)
    file_mime_response = `file --mime -b "#{path}"`
    if file_mime_response
      response_parts = file_mime_response.split(";")
      return response_parts[0]
    else
      nil
    end
  end

  def self.mime_from_filename(filename)
    mime_guesses = MIME::Types.type_for(filename).first.content_type
    if mime_guesses.length > 0
      mime_guesses.first.content_type
    else
      nil
    end
  end

  def extract_txtgz
    begin

      peek_text = ""
      Zlib::GzipReader.open(self.storage_path).each do |line|
        peek_text << line
        if peek_text.length > ALLOWED_CHAR_NUM
          self.peek_type = PeekType::PART_TEXT
          self.peek_text = peek_text
          return true
        end
      end

    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("Problem extracting gz text for task #{self.id}: #{ex.message}")
      return false
      #raise ex
    end
  end

  def extract_text
    #Rails.logger.warn("inside extract_text")
    begin
      num_bytes = File.size?(self.storage_path)
      if num_bytes > ALLOWED_DISPLAY_BYTES
        enc = Task.charset_from_path(self.storage_path) || 'UTF-8'
        peek_text = ""
        File.open(self.storage_path, 'r', encoding: enc).each do |line|
          peek_text << line
          if peek_text.length > ALLOWED_CHAR_NUM
            self.peek_type = PeekType::PART_TEXT
            self.peek_text = peek_text
            return true
          end
        end
      else
        self.peek_type = PeekType::ALL_TEXT
        self.peek_text = File.read(self.storage_path, encoding: enc)
        return true
      end
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("Problem extracting text for task #{self.id}: #{ex.message}")
      return false
    end
  end

  def extract_image
    #Rails.logger.warn("inside extract_image")
    begin
      self.peek_type = PeekType::IMAGE
      return true
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("Problem extracting image for task #{self.id}: #{ex.message}")
      return false
    end
  end

  def extract_microsoft
    #Rails.logger.warn("inside extract_microsoft")
    begin
      self.peek_type = PeekType::MICROSOFT
      return true
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("Problem extracting microsoft for task #{self.id}: #{ex.message}")
      return false
    end
  end

  def extract_pdf
    #Rails.logger.warn("inside extract_pdf")
    begin
      self.peek_type = PeekType::PDF
      return true
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("Problem extracting pdf for task #{self.id}: #{ex.message}")
      return false
    end
  end

  def create_item(item_name, item_path, item_size, media_type, is_directory)
    NestedItem.create(task_id: self.id,
                      item_path: item_path,
                      item_name: item_name,
                      item_size: item_size,
                      media_type: media_type,
                      is_directory: is_directory)
  end

  def extract_zip
    #Rails.logger.warn("inside extract_zip")
    begin
      entry_paths = []
      Zip::File.open(self.storage_path) do |zip_file|
        zip_file.each do |entry|

          if entry.name_safe?


            entry_path = valid_entry_path(entry.name)

            if entry_path && !is_ds_store(entry_path) && !is_mac_thing(entry_path)

              entry_paths << entry_path

              if is_directory(entry.name)

                create_item(entry_path,
                            name_part(entry_path),
                            entry.size,
                            'directory',
                            true)

              else

                storage_dir = File.dirname(storage_path)
                extracted_entry_path = File.join(storage_dir, entry_path)
                extracted_entry_dir = File.dirname(extracted_entry_path)
                FileUtils.mkdir_p extracted_entry_dir

                raise Exception.new("extracted entry somehow already there?!!?!") if File.exist?(extracted_entry_path)

                entry.extract(extracted_entry_path)

                raise Exception.new("extracting entry not working!") unless File.exist?(extracted_entry_path)

                mime_guess = Task.mime_from_path(extracted_entry_path) ||
                    mime_from_filename(entry.name) ||
                    'application/octet-stream'

                create_item(entry_path,
                            name_part(entry_path),
                            entry.size,
                            'directory',
                            false)
                File.delete(extracted_entry_path) if File.exist?(extracted_entry_path)
              end
            end
          end
        end
      end

      if entry_paths.length > 0
        self.peek_type = PeekType::LISTING
        self.peek_text = entry_paths_arr_to_html(entry_paths)
      else
        self.peek_type = PeekType::NONE
        report_problem("no items found for zip listing for task #{self.id}")
      end

      return true
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("problem extracting zip listing for task #{self.id}: #{ex.message}")
      #return false
      raise ex
    end
  end

  def extract_archive
    #Rails.logger.warn("inside extract_archive")
    begin

      entry_paths = []

      Archive.read_open_filename('foo.tar.gz') do |ar|
        while entry = ar.next_header

          entry_path = valid_entry_path(entry.pathname)
          if entry_path

            if !is_ds_store(entry_path) && !is_mac_thing(entry_path)
              entry_paths << entry_path

              if is_directory(entry.pathname)

                create_item(entry_path,
                            name_part(entry_path),
                            entry_size,
                            'directory',
                            true)
              else

                storage_dir = File.dirname(storage_path)
                extracted_entry_path = File.join(storage_dir, entry_path)
                extracted_entry_dir = File.dirname(extracted_entry_path)
                FileUtils.mkdir_p extracted_entry_dir

                entry_size = 0

                File.open(extracted_entry_path, 'wb') do |entry_file|
                  ar.read_data(1024) do |x|
                    entry_file.write(x)
                    entry_size = entry_size + x.length
                  end
                end

                raise("extracting non-zip entry not working!") unless File.exist?(extracted_entry_path)

                mime_guess = Task.mime_from_path(extracted_entry_path) ||
                    mime_from_filename(entry.name) ||
                    'application/octet-stream'

                create_item(entry_path,
                            name_part(entry_path),
                            entry_size,
                            mime_guess,
                            false)

                File.delete(extracted_entry_path) if File.exist?(extracted_entry_path)
              end

            end

          end
        end
      end

      if entry_paths.length > 0
        self.peek_type = PeekType::LISTING
        self.peek_text = entry_paths_arr_to_html(entry_paths)
        return true
      else
        self.peek_type = PeekType::NONE
        report_problem("no items found for archive listing for task #{self.id}")
        return false
      end

    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("problem extracting extract listing for task #{self.id}: #{ex.message}")
      return false
    end
  end

  def extract_default
    #Rails.logger.warn("inside extract_default")
    begin
      self.peek_type = PeekType::NONE
      return true
    rescue StandardError => ex
      self.status = TaskStatus::ERROR
      self.peek_type = PeekType::NONE
      self.save
      report_problem("problem creating default peek for task #{self.id}")
      return false
    end
  end

  def valid_entry_path(entry_path)
    if entry_path[-1] == '/'
      return entry_path[0...-1]
    elsif entry_path.length > 0
      return entry_path
    end
  end

  def is_directory(path)
    ends_in_slash(path) && !is_ds_store(path) && !is_mac_thing(path)
  end

  def is_mac_thing(path)
    entry_parts = path.split('/')
    entry_parts.include?('__MACOSX')
  end

  def ends_in_slash(path)
    return path[-1] == '/'
  end

  def is_ds_store(path)
    name_part(path).strip() == '.DS_Store'
  end

  def name_part(path)
    valid_path = valid_entry_path(path)
    if valid_path
      entry_parts = valid_path.split('/')
      if entry_parts.length > 1
        entry_parts[-1]
      else
        valid_path
      end
    end
  end

  def self.charset_from_path(path)

    file_info = ""

    if OS.mac?
      file_info = `file -I #{path}`
    elsif OS.linux?
      file_info = `file -i #{path}`
    else
      return nil
    end

    if file_info.length > 0
      file_info.strip.split('charset=').last
    else
      nil
    end
  end

  def entry_paths_arr_to_html(entry_paths)
    return_string = '<span class="glyphicon glyphicon-folder-open"></span> '

    return_string << self.binary_name

    entry_paths.each do |entry_path|

      if entry_path.exclude?('__MACOSX') && entry_path.exclude?('.DS_Store')

        name_arr = entry_path.split("/")

        name_arr.length.times do
          return_string << '<div class="indent"">'
        end

        if entry_path[-1] == "/" # means directory
          return_string << '<span class="glyphicon glyphicon-folder-open"></span> '

        else
          return_string << '<span class="glyphicon glyphicon-file"></span> '
        end

        return_string << name_arr.last
        name_arr.length.times do
          return_string << "</div>"
        end
      end

    end

    return return_string

  end

end
