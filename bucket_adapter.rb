class BucketAdapter
  def initialize
    @storage = Storage.new
    @client = @storage.client
    @bucket_name = @storage.bucket_name
  end

  attr_reader :storage, :client, :storage

  def upload(path)
    File.open(path, "rb") do |file|
      key = File.basename(path)

      response = client.put_object(bucket: bucket_name, key: key, body: file)

      uploading_error(path, response) if response.error
    end
  end

  def download
  end

  def delete
  end

  private

  def uploading_error(file_path, response)
    STDERR.puts("There's something went wrong with file #{file_path}: #{response.error}")
  end
end
