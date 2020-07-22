# Provides helper methods to unzip, publish, and launch LessonContent
# on AWS S3
class LessonContentPublisher

  S3_OBJECT_PREFIX = "lessons".freeze
  INDEX_FILE = "index.html".freeze

  # Publicly accessible URL for the lesson
  # The "filekey" is the "key" attribute of an ActiveStorage zipfile.
  # Aka the name of the zipfile on S3.
  def self.launch_url(filekey, bucket = nil)
    bucket = AwsS3Bucket.new unless bucket
    bucket.object(s3_object_key(filekey, INDEX_FILE)).public_url
  end

  # Publishes an ActiveStorage zipfile (with a "key" attribute)
  # to S3 such that calling LessonContentPublisher.launch_url(key)
  # will return the publicly accessible URL for it's index.html
  def self.publish(zipfile)
      bucket = AwsS3Bucket.new

      zipfile.open do |file|
        Zip::File.open(file.path) do |zip_file|
          zip_file.each do |entry|
            next unless entry.file?
            s3_object = bucket.object(s3_object_key(zipfile.key, entry.name))
            s3_object.put({
                acl: "public-read",
                body: entry.get_input_stream.read,
            })
          end
        end
      end

      launch_url(zipfile.key, bucket)
  end



  class << self
    private
    # Return an S3 object key for a filename in the zip
    # relative to the filekey (aka the zipfile key)
    def s3_object_key(filekey, filename)
      [ S3_OBJECT_PREFIX, filekey, filename ].join("/")
    end
  
  end

  # Wrapper for an AWS S3 bucket. Takes care of authentication.
  class AwsS3Bucket
    # Calls "object" on the authenticated bucket.
    def object(*args)
      @bucket ||= begin
        credentials = Aws::Credentials.new(Rails.application.secrets.aws_access_key, Rails.application.secrets.aws_secret_access_key)
        Aws.config.update({credentials: credentials})
        Aws::S3::Resource.new(region: Rails.application.secrets.aws_region).bucket(Rails.application.secrets.aws_files_bucket)
      end
      @bucket.object(*args)
    end

  end

end

