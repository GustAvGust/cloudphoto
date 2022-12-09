require "inifile"
require "./storage"
require "fileutils"

class Init
  def self.call
    @@storage = Storage.new(is_init: true)
    get_config_attributes
    setup_config
    create_bucket unless bucket_exists?
  end

  private

  def self.get_config_attributes
    print "Set aws_access_key_id: "
    @@aws_access_key_id = STDIN.gets.chomp

    print "Set aws_secret_access_key: "
    @@aws_secret_access_key = STDIN.gets.chomp

    print "Set bucket: "
    @@bucket_name = STDIN.gets.chomp
  end

  def self.setup_config
    create_config_dir unless config_dir_exists?

    dirname = File.dirname(@@storage.class::CONFIG_FILE_PATH)

    create_dir(dirname) unless File.directory?(dirname)

    File.write(@@storage.class::CONFIG_FILE_PATH, config_content)

    @@storage.setup
  end

  def self.config_dir_exists?
    Dir.exists?(File.expand_path("~/.config"))
  end

  def self.create_config_dir
    create_dir(File.expand_path("~/.config"))
  end

  def self.create_dir(path)
    Dir.chdir(File.dirname(path)) do
      Dir.mkdir(File.basename(path))
    end
  end

  def self.config_content
    "[default]\n" +
    "aws_access_key_id = #{@@aws_access_key_id}\n" +
    "aws_secret_access_key = #{@@aws_secret_access_key}\n" +
    "bucket = #{@@bucket_name}\n" +
    "region = ru-central1\n" +
    "endpoint = https://storage.yandexcloud.net\n"
  end

  def self.create_bucket
    response = @@storage.client.create_bucket(bucket: @@bucket_name)

    if bucket_created?(response)
      puts "Bucket '#{@@bucket_name}' created."
    else
      puts "Bucket '#{@@bucket_name}' not created. Program will stop."
      exit 1
    end
  end

  def self.bucket_created?(response)
    return response.location == ('/' + @@bucket_name)
  rescue StandardError => error
    puts "Error creating bucket: #{error.message}"

    return false
  end

  def self.bucket_exists?
    response = @@storage.client.list_buckets
    response.buckets.each do |bucket|
      return true if bucket.name == @@bucket_name
    end
    return false
  rescue StandardError => error
    puts "Error listing buckets: #{error.message}"
    return false
  end
end
