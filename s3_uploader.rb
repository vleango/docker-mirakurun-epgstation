require 'rubygems'
require 'aws-sdk-s3'
require 'active_support/all'

class S3
  INTERVAL_BEFORE_UPLOAD = 5.hours.ago
  attr_reader :client, :bucket_name, :path

    def initialize(path:)
      credentials = Aws::Credentials.new(
        ENV['KEY'],
        ENV['SECRET']
      )
      @client = Aws::S3::Client.new(
        region: ENV['REGION'],
        credentials: credentials
      )
      @bucket_name = ENV['BUCKET_NAME']
      @path = path
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
        Dir.entries("#{path}/.").each do |filename|
          next if ['.', '..'].include?(filename)

          remote_file = list_objects.detect { |file| file[:name] == filename }
          file = File.open("#{path}/#{filename}")

          if INTERVAL_BEFORE_UPLOAD > file.mtime && (remote_file.blank? || remote_file[:size] < file.size)
            puts "uploading: #{filename}..."
            client.put_object(bucket: bucket_name, key: filename, body: file)
          end
        end
        true
      end

      def clean_files
        Dir.entries("#{path}/.").each do |filename|
          next if ['.', '..'].include?(filename)

          remote_file = list_objects.detect { |file| file[:name] == filename }
          file = File.open("#{path}/#{filename}")

          if remote_file.present? && file.size == remote_file[:size]
            puts "removing #{filename}..."
            File.delete("#{path}/#{filename}")
          else
            puts "keeping #{filename} - Different file sizes!"
          end
        end
      end

end

puts "S3 Uploader Start - #{Time.now.in_time_zone('Asia/Tokyo')} JST / #{Time.now.in_time_zone('Central Time (US & Canada)')} CST -----------------------------------------------------------"
path = "/home/vleango/projects/docker-mirakurun-epgstation/encoded"

begin
s3 = S3.new(path: path)
#s3.clean_files
#s3.upload_files
rescue => e
  puts "Error: #{e}"
end

puts "S3 Uploader Finished - #{Time.now.in_time_zone('Asia/Tokyo')} JST / #{Time.now.in_time_zone('Central Time (US & Canada)')} CST ---------------------------------------------------------"
