require "base64"

require "./albums_content"
require "./storage"

class Upload
  def self.call(options)
    @@storage = Storage.new
    @@client = @@storage.client
    @@bucket_name = @@storage.bucket_name

    @@album = options[:album]
    @@raw_photo_dir = options[:photo_dir]

    check_dir_permissions

    unless albums.keys.include?(album_hash)
      albums[album_hash] = album_struct
    end

    albums[album_hash]["photos"] = (albums[album_hash]["photos"] + generated_photos).uniq

    upload_photos
    upload_albums_content(albums)
  end

  private_class_method

  def self.albums
    @albums ||= albums_content.get
  end

  def self.albums_content
    @albums_content ||= AlbumsContent.new
  end

  def self.album_hash
    @album_hash ||= Base64.encode64(@@album)
  end

  def self.album_struct
    {
      "name" => @@album,
      "photos" => []
    }
  end

  def self.generated_photos
    photos = Dir.entries(photo_dir).select { |file| file =~ /.*\.(jpg|jpeg)/ }

    abort("#{photo_dir} has no photos!") if photos.empty?

    photos.map do |photo|
      { Base64.encode64(photo) => photo }
    end
  end

  def self.check_dir_permissions
    abort("Can not write to #{@raw_photo_dir}") unless File.readable?(photo_dir) && File.executable?(photo_dir)
  end

  def self.photo_dir
    @photo_dir ||= find_dir
  end

  def self.find_dir
    return Dir.pwd if @@raw_photo_dir.nil?

    if Dir.exist?("#{Dir.pwd}/#{@@raw_photo_dir}")
      "#{Dir.pwd}/#{@@raw_photo_dir}"
    elsif Dir.exist?(@@raw_photo_dir)
      @@raw_photo_dir
    else
      abort("There's no such directory!")
    end
  end

  def self.upload_photos
    generated_photos.each do |photo|
      file_name = "#{photo_dir}/#{photo.values[0]}"

      if File.readable?(file_name)
        File.open(file_name, 'rb') do |file|
          key = "#{album_hash}/#{photo.keys[0]}"
          resp = @@client.put_object(bucket: @@bucket_name, key: key, body: file)
          uploading_error(photo, resp.error) if resp.error
        end
      else
        uploading_error(photo, "Can't read file") 
      end
    end
  end

  def self.uploading_error(photo, error)
    STDERR.puts("There's something went wrong with photo #{photo.values[0]}: #{error}")
    delete_from_content(photo.keys[0])
  end

  def self.delete_from_content(photo_key)
    albums[album_hash]["photos"].reject! { |item| item.keys.include?(photo_key) }
  end

  def self.upload_albums_content(albums)
    albums_content.upload(albums)
  end
end
