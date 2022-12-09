require "base64"

require "./albums_content"
require "./storage"

class Download
  def self.call(options)
    @@storage = Storage.new
    @@client = @@storage.client
    @@bucket_name = @@storage.bucket_name

    @album_name = options[:album_name]
    @raw_photos_dir = options[:photos_dir]

    abort("There's no such album in the bucket") if album.nil?

    check_dir_permissions
    download_photos
  end

  private

  def self.album
    @album ||= albums_content[album_hash]
  end

  def self.album_hash
    @album_hash ||= Base64.encode64(@album_name)
  end

  def self.albums_content
    @albums_content ||= AlbumsContent.new.get
  end

  def self.download_photos
    album["photos"].map do |el|
      file_name = el.values[0]
      key = "#{album_hash}/#{el.keys[0]}"

      @@client.get_object({ bucket: @@bucket_name, key: key }, target: "#{photo_dir}/#{file_name}")
    end
  end


  def self.check_dir_permissions
    abort("Can not write to #{@raw_photos_dir}") unless File.writable?(photo_dir) && File.executable?(photo_dir)
  end

  def self.photo_dir
    # check rights
    @photo_dir ||= find_dir
  end

  def self.find_dir
    return Dir.pwd if @raw_photos_dir.nil?

    if Dir.exist?("#{Dir.pwd}/#{@raw_photos_dir}")
      "#{Dir.pwd}/#{@raw_photos_dir}"
    elsif Dir.exist?(@raw_photos_dir)
      @raw_photos_dir
    else
      abort("There's no such directory!")
    end
  end
end
