require "base64"

require "./albums_content"

class List
  def self.call(options = {})
    @album_name = options[:album_name]

    if @album_name
      print_album_photos
    else
      print_albums
    end

    return nil
  end

  private

  def self.print_album_photos
    abort("There's no such album in the bucket") if album.nil?
    abort("There's no photo in the album") if album.empty?

    album["photos"].map(&:values)
      .each { |el| STDOUT.puts(el[0])  }
  end

  def self.print_albums
    abort("There's no albums in the bucket") if albums_content.empty?

    albums_content.each { |el| STDOUT.puts(el[1].dig("name")) }
  end

  def self.album
    @album ||= albums_content[album_hash]
  end

  def self.album_hash
    @album_hash ||= Base64.encode64(@album_name)
  end

  def self.albums_content
    @albums_content ||= AlbumsContent.new.get
  end
end
