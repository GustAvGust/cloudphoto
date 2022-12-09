require "aws-sdk-s3"
require "inifile"

class Storage
  CONFIG_FILE_PATH = File.expand_path("~/.config/cloudphoto/cloudphotorc").freeze

  def initialize(is_init: false)
    return if is_init

    valid_config? ? setup : abort("config error")
  end

  def setup
    Aws.config.update({
      credentials: Aws::Credentials.new(parsed_config.dig("aws_access_key_id"), parsed_config.dig("aws_secret_access_key")),
      endpoint: parsed_config.dig("endpoint"),
      region: parsed_config.dig("region")
    })

    @client = Aws::S3::Client.new(retry_limit: 0)
    @bucket_name = parsed_config.dig("bucket")
    @bucket = Aws::S3::Bucket.new(name: @bucket_name)
  end

  def valid_config?
    return false unless File.file?(CONFIG_FILE_PATH)
    config = parsed_config

    config["aws_access_key_id"] &&
    config["aws_secret_access_key"] &&
    config["bucket"] &&
    config["region"] &&
    config["endpoint"]
  end

  attr_reader :client, :bucket_name, :bucket

  private

  def parsed_config
    IniFile.load(CONFIG_FILE_PATH).to_h.dig("default")
  end
end
