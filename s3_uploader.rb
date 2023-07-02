require 'rubygems'
require 'aws-sdk-s3'
require 'active_support/all'

#path = "/home/vleango/projects/docker-mirakurun-epgstation/encoded"

class S3
  INTERVAL_BEFORE_UPLOAD = 5.hours.ago
  attr_reader :client, :bucket_name, :path

  def initialize
    credentials = Aws::Credentials.new(
      ENV['KEY'],
      ENV['SECRET']
    )
    @client = Aws::S3::Client.new(
      region: ENV['REGION'],
      credentials: credentials
    )
    @bucket_name = ENV['BUCKET_NAME']
    @path = ENV['UPLOAD_PATH']
  end

  def list_buckets
    response = client.list_buckets
    if response.buckets.count.zero?
      puts 'No buckets.'
      []
    else
      response.buckets.map(&:name)
    end
  rescue StandardError => e
    puts "Error listing buckets: #{e.message}"
    []
  end

  def create_bucket
    client.create_bucket(bucket: bucket_name)
  rescue StandardError => e
    puts "Error creating bucket: #{e.message}"
  end

  def list_objects
    @list_objects ||= client.list_objects_v2(bucket: bucket_name).contents.map do |content|
      { name: content[:key], size: content[:size] }
    end
  rescue StandardError => e
    puts "Error listing objects: #{e.message}"
  end

  def upload_files
    Dir.glob("#{path}/**/*").each do |filename|
      unless File.directory?(filename)
        key = filename.gsub("#{path}/", "")
        remote_file = list_objects.detect { |file| file[:name] == key }
        file = File.open(filename)

        if INTERVAL_BEFORE_UPLOAD > file.mtime && (remote_file.blank? || remote_file[:size] < file.size)
          puts "uploading: #{key}..."
          client.put_object(bucket: bucket_name, key: key, body: file)
        end

      end
    end
    true
  end

  def clean_files
    Dir.glob("#{path}/**/*").each do |filename|
      unless File.directory?(filename)
        key = filename.gsub("#{path}/", "")
        remote_file = list_objects.detect { |file| file[:name] == key }
        file = File.open(filename)
        
        if remote_file.present? && file.size == remote_file[:size]
          puts "removing #{filename}..."
          File.delete(filename)
        else
          puts "keeping #{filename} - Different file sizes!"
        end

      end
    end
  end

end

puts "S3 Uploader Start - #{Time.now.in_time_zone('Asia/Tokyo')} JST / #{Time.now.in_time_zone('Central Time (US & Canada)')} CST -----------------------------------------------------------"

begin
s3 = S3.new
s3.clean_files
s3.upload_files
rescue => e
  puts "Error: #{e}"
end

puts "S3 Uploader Finished - #{Time.now.in_time_zone('Asia/Tokyo')} JST / #{Time.now.in_time_zone('Central Time (US & Canada)')} CST ---------------------------------------------------------"
