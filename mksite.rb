require "base64"
require "./bucket_adapter"
require "./albums_content"

class MkSite
  def self.call
    @@bucket_adapter = BucketAdapter.new

    @@storage = @@bucket_adapter.storage
    @@client = @@storage.client
    @@bucket_name = @@storage.bucket_name
    @@bucket = @@storage.bucket


    @@client.put_bucket_acl(
      bucket: @@bucket_name,
      acl: "public-read-write"
    )

    bucket_website_configure("index.html", "error.html")

    generate_albums_pages
    generate_index_page

    generate_error_page

    return website_url
  end

  private

  def self.bucket_website_configure(index_document, error_document)
    @@client.put_bucket_website(
      bucket: @@bucket_name,
      website_configuration: {
        index_document: {
          suffix: index_document
        },
        error_document: {
          key: error_document
        }
      }
    )

    return true
  rescue StandardError => e
    puts "Error configuring bucket as a static website: #{e.message}"
    return false
  end

  def self.generate_albums_pages
    albums.each_with_index { |album, i| generate_album_page(album, i) }
  end

  def self.albums
    albums_content.map { |el| el[1].dig("name") }
  end

  def self.generate_album_page(album, temp_num)
    content = "<!doctype html>" \
    "<html>" \
        "<head>" \
            "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdnjs.cloudflare.com/ajax/libs/galleria/1.6.1/themes/classic/galleria.classic.min.css\" />" \
            "<style>" \
                ".galleria{ width: 960px; height: 540px; background: #000 }" \
            "</style>" \
            "<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js\"></script>" \
            "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/galleria/1.6.1/galleria.min.js\"></script>" \
            "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/galleria/1.6.1/themes/classic/galleria.classic.min.js\"></script>" \
        "</head>" \
        "<body>" \
            "<div class=\"galleria\">" \
                "#{album_photos_tags(album)}" \
            "</div>" \
            "<p>Вернуться на <a href=\"index.html\">главную страницу</a> фотоархива</p>" \
            "<script>" \
                "(function() {" \
                    "Galleria.run(\".galleria\");" \
                "}());" \
            "</script>" \
        "</body>" \
    "</html>"

    io = StringIO.new(content)

    @@client.put_object(bucket: @@bucket_name, acl: "public-read", key: "album#{temp_num}.html", body: io)
  end

  def self.album_hash(album)
    Base64.encode64(album)
  end

  def self.album_photos_tags(album)
    tags = ""

    album_photos(album).each do |photo|
      tags += "<img src=#{photo_url(album, photo)} data-title=\"#{photo}\">"
    end

    tags
  end

  def self.album_photos(album)
    albums_content[album_hash(album)]["photos"].map(&:values).flatten
  end

  def self.photo_url(album, photo)
    @@bucket.object("#{encode64(album)}/#{encode64(photo)}").public_url
  end

  def self.encode64(str)
    Base64.encode64(str)
  end

  def self.albums_content
    @albums_content ||= AlbumsContent.new.get
  end

  def self.generate_index_page
    content = "<!doctype html>" \
    "<html>" \
        "<head>" \
            "<title>Фотоархив</title>" \
        "</head>" \
    "<body>" \
        "<h1>Фотоархив</h1>" \
        "<ul>" \
            "#{albums_tags}" \
        "</ul>" \
    "</body"

    io = StringIO.new(content)

    @@client.put_object(bucket: @@bucket_name, acl: "public-read", key: "index.html", body: io)
  end

  def self.albums_tags
    tags = ""
    albums.each_with_index do |album, i|
      tags += "<li><a href=album#{i}.html>#{album}</a></li>"
    end
    tags
  end

  def self.generate_error_page
    content = "<!doctype html>" \
    "<html>" \
        "<head>" \
            "<title>Фотоархив</title>" \
        "</head>" \
    "<body>" \
        "<h1>Ошибка</h1>" \
        "<p>Ошибка при доступе к фотоархиву. Вернитесь на <a href=index.html>главную страницу</a> фотоархива.</p>" \
    "</body>" \
    "</html>"

    io = StringIO.new(content)

    @@client.put_object(bucket: @@bucket_name, acl: "public-read", key: "error.html", body: io)
  end

  def self.website_url
    "https://#{@@bucket_name}.website.yandexcloud.net/"
  end
end
