require "base64"

require "./albums_content"
require "./storage"

class Delete
  def self.call(options = {})
    @@storage = Storage.new
    @@client = @@storage.client
    @@bucket_name = @@storage.bucket_name

    @album_name = options[:album_name]
    @photo_name = options[:photo]

    abort("There's no such album in the bucket") if album.nil?

    if @photo_name
      delete_photo
    else
      delete_album
    end

    albums_content.upload(albums)
    return nil
  end

  private

  def self.delete_photo
    abort("There's no such photo in the album") if photo.nil?

    @@client.delete_object(bucket: @@bucket_name, key: "#{album_hash}/#{photo.keys[0]}")
    album["photos"] = album["photos"].reject{ |el| el == photo }
  end

  def self.delete_album
    abort("There's no such album in the bucket") if album.nil?

    keys_for_deletion = album["photos"].map do |el|
      { key: "#{album_hash}/#{el.keys[0]}" }
    end
    @@client.delete_objects({
      bucket: @@bucket_name,
      delete: {
        objects: keys_for_deletion,
        quiet: false,
      },
    })

    albums.delete(album_hash)
  end

  def self.photo
    # {"a2VybWl0IGNhci5qcGVn%0A.jpeg"=>"kermit car.jpeg"}

    @photo ||= album["photos"].filter{ |el| el.values[0] == @photo_name }.first
  end

  def self.album
    @album ||= albums[album_hash]
  end

  def self.photo_hash
    @photo_hash ||= Base64.encode64(@photo_name)
  end

  def self.album_hash
    @album_hash ||= Base64.encode64(@album_name)
  end

  def self.albums
    @albums ||= albums_content.get
  end

  def self.albums_content
    @albums_content ||= AlbumsContent.new
  end
end
