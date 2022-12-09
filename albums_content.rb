require "aws-sdk-s3"
require "./storage"

class AlbumsContent
  def initialize
    @file_name = 'albums_content.json'
    @storage = Storage.new

    @bucket = @storage.bucket_name
    @client = @storage.client
  end

  def get
    resp = client.get_object(bucket: bucket, key: file_name).body.read
    JSON.parse(resp.gsub("\n", ""))
  end

  def upload(content_info)
    io = StringIO.new(content_info.to_json)
    client.put_object(bucket: bucket, key: file_name, body: io)
  end

  private

  attr_reader :file_name, :bucket, :client
end
