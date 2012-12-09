module Woody
  module Deployer
    def self.deploy
      touchedfiles = Array.new
      deploy_r touchedfiles

      # Purge left over files
      purge_bucket touchedfiles
    end

    private

    def self.deploy_r(touchedfiles, subdir = "")
      puts "Deploying... " if subdir == ""
      Dir.foreach("output/#{subdir}") do |item|
        next if item == '.' or item == '..'
        begin
          touchedfiles << "#{subdir}#{item}"
          upload("#{subdir}#{item}", "output/#{subdir}#{item}")
        rescue Errno::EISDIR
          deploy_r touchedfiles, "#{subdir}#{item}/"
        end
      end
    end

    def self.purge_bucket(touchedfiles)
      bucket = AWS::S3::Bucket.find $bucketname
      bucket.objects.each do |object|
        object.delete unless touchedfiles.include? object.key
      end
    end

    def self.filehash(filepath)
      sha1 = Digest::SHA1.new
      File.open(filepath) do|file|
        buffer = ''
        # Read the file 512 bytes at a time
        while not file.eof
          file.read(512, buffer)
          sha1.update(buffer)
        end
      end
      return sha1.to_s
    end

    def self.upload(objectname, filepath)
      # Generate hash of file
      hash = filehash filepath

      # Get hash of version already uploaded, if available.
      begin
        object = AWS::S3::S3Object.find objectname, $bucketname
        oldhash = object.metadata['hash']
      rescue AWS::S3::NoSuchKey
        # File not uploaded yet
        oldhash = nil
      end
      unless hash == oldhash
        # Don't reupload if file hasn't changed
        puts "#{objectname}: Uploading"
        AWS::S3::S3Object.store(objectname, open(filepath), $bucketname, access: :public_read, 'x-amz-meta-hash' => hash)
      else
        puts "#{objectname}: Not uploading, hasn't changed since last time."
      end
    end
  end
end