# frozen_string_literal: true

require "digest"
require "fileutils"

class UploadFile < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :author, :class_name => "User"

  acts_as_paranoid :column => 'deleted_at', :column_type => 'time'
  validates_presence_of :filename, :author
  validates_length_of :filename, :maximum => 255
  validates_length_of :disk_filename, :maximum => 255
  validates_length_of :description, :maximum => 255
  validate :validate_max_file_size, :validate_file_extension

  cattr_accessor :storage_path
  @@storage_path = File.join(Rails.root, "files", "upload_files")

  cattr_accessor :thumbnails_storage_path
  @@thumbnails_storage_path = File.join(Rails.root, "tmp", "thumbnails")

  before_create :files_to_final_location
  after_rollback :delete_from_disk, :on => :create
  after_commit :delete_from_disk, :on => :destroy
  after_commit :reuse_existing_file_if_possible, :on => :create

  safe_attributes 'filename', 'content_type', 'description'

  # Returns an unsaved copy of the upload_file
  def copy(attributes=nil)
    copy = self.class.new
    copy.attributes = self.attributes.dup.except("id", "downloads")
    copy.attributes = attributes if attributes
    copy
  end

  def validate_max_file_size
    if @temp_file && self.filesize > Setting.attachment_max_size.to_i.kilobytes
      errors.add(:base, l(:error_attachment_too_big, :max_size => Setting.attachment_max_size.to_i.kilobytes))
    end
  end

  def validate_file_extension
    if @temp_file
      extension = File.extname(filename)
      unless self.class.valid_extension?(extension)
        errors.add(:base, l(:error_attachment_extension_not_allowed, :extension => extension))
      end
    end
  end

  def file=(incoming_file)
    unless incoming_file.nil?
      @temp_file = incoming_file
      if @temp_file.respond_to?(:original_filename)
        self.filename = @temp_file.original_filename
        self.filename.force_encoding("UTF-8")
      end
      if @temp_file.respond_to?(:content_type)
        self.content_type = @temp_file.content_type.to_s.chomp
      end
      self.filesize = @temp_file.size
    end
  end

  def file
    nil
  end

  def filename=(arg)
    write_attribute :filename, sanitize_filename(arg.to_s)
    filename
  end

  # Copies the temporary file to its final location
  # and computes its MD5 hash
  def files_to_final_location
    if @temp_file
      self.disk_directory = target_directory
      self.disk_filename = UploadFile.disk_filename(filename, disk_directory)
      logger.info("Saving upload file '#{self.diskfile}' (#{@temp_file.size} bytes)") if logger
      path = File.dirname(diskfile)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end
      sha = Digest::SHA256.new
      File.open(diskfile, "wb") do |f|
        if @temp_file.respond_to?(:read)
          buffer = ""
          while (buffer = @temp_file.read(8192))
            f.write(buffer)
            sha.update(buffer)
          end
        else
          f.write(@temp_file)
          sha.update(@temp_file)
        end
      end
      self.digest = sha.hexdigest
    end
    @temp_file = nil

    if content_type.blank? && filename.present?
      self.content_type = Redmine::MimeType.of(filename)
    end
    # Don't save the content type if it's longer than the authorized length
    if self.content_type && self.content_type.length > 255
      self.content_type = nil
    end
  end

  # Deletes the file from the file system if it's not referenced by other upload_files
  def delete_from_disk
    if UploadFile.where("disk_filename = ? AND id <> ?", disk_filename, id).empty?
      delete_from_disk!
    end
  end

  # Returns file's location on disk
  def diskfile
    File.join(self.class.storage_path, disk_directory.to_s, disk_filename.to_s)
  end

  def diskfile_deleted
    File.join(self.class.storage_path, 'deleted', disk_directory.to_s, disk_filename.to_s)
  end

  def title
    title = filename.dup
    if description.present?
      title << " (#{description})"
    end
    title
  end

  def increment_download
    increment!(:downloads)
  end

  def image?
    !!(self.filename =~ /\.(bmp|gif|jpg|jpe|jpeg|png)$/i)
  end

  def thumbnailable?
    Redmine::Thumbnail.convert_available? && (
      image? || (is_pdf? && Redmine::Thumbnail.gs_available?)
    )
  end

  def visible?
    true
  end

  # Returns the full path the upload_file thumbnail, or nil
  # if the thumbnail cannot be generated.
  def thumbnail(options={})
    if thumbnailable? && readable?
      size = options[:size].to_i
      if size > 0
        # Limit the number of thumbnails per image
        size = (size / 50.0).ceil * 50
        # Maximum thumbnail size
        size = 800 if size > 800
      else
        size = Setting.thumbnails_size.to_i
      end
      size = 100 unless size > 0
      target = thumbnail_path(size)

      begin
        Redmine::Thumbnail.generate(self.diskfile, target, size, is_pdf?)
      rescue => e
        logger.error "An error occured while generating thumbnail for #{disk_filename} to #{target}\nException was: #{e.message}" if logger
        return nil
      end
    end
  end

  # Deletes all thumbnails
  def self.clear_thumbnails
    Dir.glob(File.join(thumbnails_storage_path, "*.thumb")).each do |file|
      File.delete file
    end
  end

  def is_text?
    Redmine::MimeType.is_type?('text', filename) || Redmine::SyntaxHighlighting.filename_supported?(filename)
  end

  def is_markdown?
    Redmine::MimeType.of(filename) == 'text/markdown'
  end

  def is_textile?
    Redmine::MimeType.of(filename) == 'text/x-textile'
  end

  def is_image?
    Redmine::MimeType.is_type?('image', filename)
  end

  def is_diff?
    /\.(patch|diff)$/i.match?(filename)
  end

  def is_pdf?
    Redmine::MimeType.of(filename) == "application/pdf"
  end

  def is_video?
    Redmine::MimeType.is_type?('video', filename)
  end

  def is_audio?
    Redmine::MimeType.is_type?('audio', filename)
  end

  def previewable?
    is_text? || is_image? || is_video? || is_audio?
  end

  # Returns true if the file is readable
  def readable?
    disk_filename.present? && File.readable?(diskfile)
  end

  # Returns the upload_file token
  def token
    "#{id}.#{digest}"
  end

  def self.find_by_token(token)
    if token.to_s =~ /^(\d+)\.([0-9a-f]+)$/
      upload_file_id, upload_file_digest = $1, $2
      UploadFile.find_by(:id => upload_file_id, :digest => upload_file_digest)
    end
  end

  # Bulk attaches a set of files to an object
  #
  # Returns a Hash of the results:
  # :files => array of the attached files
  # :unsaved => array of the files that could not be attached
  def self.attach_files(obj, upload_files)
    result = obj.save_upload_files(upload_files, User.current)
    obj.attach_saved_upload_files
    result
  end

  # Updates the filename and description of a set of upload_files
  # with the given hash of attributes. Returns true if all
  # upload_files were updated.
  #
  # Example:
  #   UploadFile.update_upload_files(upload_files, {
  #     4 => {:filename => 'foo'},
  #     7 => {:filename => 'bar', :description => 'file description'}
  #   })
  #
  def self.update_upload_files(upload_files, params)
    params = params.transform_keys {|key| key.to_i}

    saved = true
    transaction do
      upload_files.each do |upload_file|
        if p = params[upload_file.id]
          upload_file.filename = p[:filename] if p.key?(:filename)
          upload_file.description = p[:description] if p.key?(:description)
          saved &&= upload_file.save
        end
      end
      unless saved
        raise ActiveRecord::Rollback
      end
    end
    saved
  end

  def self.latest_attach(upload_files, filename)
    upload_files.sort_by(&:created_on).reverse.detect do |att|
      filename.casecmp(att.filename) == 0
    end
  end

  # Moves an existing upload_file to its target directory
  def move_to_target_directory!
    return unless !new_record? & readable?

    src = diskfile
    self.disk_directory = target_directory
    dest = diskfile

    return if src == dest

    if !FileUtils.mkdir_p(File.dirname(dest))
      logger.error "Could not create directory #{File.dirname(dest)}" if logger
      return
    end

    if !FileUtils.mv(src, dest)
      logger.error "Could not move upload_file from #{src} to #{dest}" if logger
      return
    end

    update_column :disk_directory, disk_directory
  end

  # Moves existing upload_files that are stored at the root of the files
  # directory (ie. created before Redmine 2.3) to their target subdirectories
  def self.move_from_root_to_target_directory
    UploadFile.where("disk_directory IS NULL OR disk_directory = ''").find_each do |upload_file|
      upload_file.move_to_target_directory!
    end
  end

  # Updates digests to SHA256 for all upload_files that have a MD5 digest
  # (ie. created before Redmine 3.4)
  def self.update_digests_to_sha256
    UploadFile.where("length(digest) < 64").find_each do |upload_file|
      upload_file.update_digest_to_sha256!
    end
  end

  # Updates upload_file digest to SHA256
  def update_digest_to_sha256!
    if readable?
      sha = Digest::SHA256.new
      File.open(diskfile, 'rb') do |f|
        while buffer = f.read(8192)
          sha.update(buffer)
        end
      end
      update_column :digest, sha.hexdigest
    end
  end

  # Returns true if the extension is allowed regarding allowed/denied
  # extensions defined in application settings, otherwise false
  def self.valid_extension?(extension)
    denied, allowed = [:attachment_extensions_denied, :attachment_extensions_allowed].map do |setting|
      Setting.send(setting)
    end
    if denied.present? && extension_in?(extension, denied)
      return false
    end
    if allowed.present? && !extension_in?(extension, allowed)
      return false
    end
    true
  end

  # Returns true if extension belongs to extensions list.
  def self.extension_in?(extension, extensions)
    extension = extension.downcase.sub(/\A\.+/, '')

    unless extensions.is_a?(Array)
      extensions = extensions.to_s.split(",").map(&:strip)
    end
    extensions = extensions.map {|s| s.downcase.sub(/\A\.+/, '')}.reject(&:blank?)
    extensions.include?(extension)
  end

  # Returns true if upload_file's extension belongs to extensions list.
  def extension_in?(extensions)
    self.class.extension_in?(File.extname(filename), extensions)
  end

  # returns either MD5 or SHA256 depending on the way self.digest was computed
  def digest_type
    digest.size < 64 ? "MD5" : "SHA256" if digest.present?
  end

  private

  def reuse_existing_file_if_possible
    original_diskfile = nil
    reused = with_lock do
      if existing = UploadFile
                      .where(digest: self.digest, filesize: self.filesize)
                      .where('id <> ? and disk_filename <> ?',
                             self.id, self.disk_filename)
                      .first
        existing.with_lock do
          original_diskfile = self.diskfile
          existing_diskfile = existing.diskfile
          if File.readable?(original_diskfile) &&
            File.readable?(existing_diskfile) &&
            FileUtils.identical?(original_diskfile, existing_diskfile)
            self.update_columns disk_directory: existing.disk_directory,
                                disk_filename: existing.disk_filename
          end
        end
      end
    end
    if reused
      File.delete(original_diskfile)
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound
    # Catch and ignore lock errors. It is not critical if deduplication does
    # not happen, therefore we do not retry.
    # with_lock throws ActiveRecord::RecordNotFound if the record isnt there
    # anymore, thats why this is caught and ignored as well.
  end

  # Physically deletes the file from the file system
  def delete_from_disk!
    if disk_filename.present? && File.exist?(diskfile)
      diskfile_deleted_path = File.dirname(diskfile_deleted)

      unless File.directory?(diskfile_deleted_path)
        FileUtils.mkdir_p(diskfile_deleted_path)
      end

      FileUtils.mv(diskfile, diskfile_deleted)
    end

    Dir[thumbnail_path("*")].each do |thumb|
      File.delete(thumb)
    end
  end

  def thumbnail_path(size)
    File.join(self.class.thumbnails_storage_path, "#{digest}_#{filesize}_#{size}.thumb")
  end

  def sanitize_filename(value)
    # get only the filename, not the whole path
    just_filename = value.gsub(/\A.*(\\|\/)/m, '')

    # Finally, replace invalid characters with underscore
    just_filename.gsub(/[\/\?\%\*\:\|\"\'<>\n\r]+/, '_')
  end

  # Returns the subdirectory in which the upload_file will be saved
  def target_directory
    time = created_on || DateTime.now
    time.strftime("%Y/%m")
  end

  # Singleton class method is public
  class << self
    # Returns an ASCII or hashed filename that do not
    # exists yet in the given subdirectory
    def disk_filename(filename, directory=nil)
      timestamp = DateTime.now.strftime("%y%m%d%H%M%S")
      ascii = ''
      if %r{^[a-zA-Z0-9_\.\-]*$}.match?(filename) && filename.length <= 50
        ascii = filename
      else
        ascii = Digest::MD5.hexdigest(filename)
        # keep the extension if any
        ascii << $1 if filename =~ %r{(\.[a-zA-Z0-9]+)$}
      end
      while File.exist?(File.join(storage_path, directory.to_s,
                                  "#{timestamp}_#{ascii}"))
        timestamp.succ!
      end
      "#{timestamp}_#{ascii}"
    end
  end
end
