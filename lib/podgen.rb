require "podgen/version"

require 'yaml'
require 'erubis'
require 'mp3info'
require 'aws/s3'
require 'digest'
require 'fileutils'


module Podgen
  $source_root = File.expand_path("../../templates", __FILE__)

  # Load configuration
  def self.init
    begin
      $config = YAML.load_file("podgen-config.yml")
    rescue Errno::ENOENT
      puts "This doesn't look like a valid PodGen site directory!"
      return
    end
    
    AWS::S3::Base.establish_connection!(
      :access_key_id     => $config['s3']['accesskey']['id'], 
      :secret_access_key => $config['s3']['accesskey']['secret']
    )
    AWS::S3::DEFAULT_HOST.replace $config['s3']['hostname']
    $bucketname = $config['s3']['bucket']  
    $itunes_image_url = "FILL IN URL"
  end
    
  def self.new_site(name)
    puts "Creating new site '#{name}'..."
    if File.directory?(name)
      puts "Error: directory '#{name}' already exists!"
      return false
    end
    
    cdir_p(name)
    cpy_t("podgen-config.yml", "#{name}/podgen-config.yml")
    
    cdir_p("#{name}/templates")
    cpy_t("layout.html", "#{name}/templates/layout.html")
    cpy_t("index.html", "#{name}/templates/index.html")
    cpy_t("episode.html", "#{name}/templates/episode.html")
        
    cdir_p("#{name}/templates/assets")
    cpy_t("stylesheet.css", "#{name}/templates/assets/stylesheet.css")
    
    cdir_p("#{name}/content")
    cpy_t("metadata.yml", "#{name}/content/metadata.yml")

    
    cdir_p("#{name}/output")
    cdir_p("#{name}/output/assets")
    cdir_p("#{name}/output/assets/mp3")
    cdir_p("#{name}/output/episode")    
    
    puts "Done!"
    puts "Now, do `cd #{name}` then edit the config file, podgen-config.yml."
  end
  
  def self.update_templates
    puts "Updating templates..."
    cpy_t("layout.html", "templates/layout.html")
    cpy_t("index.html", "templates/index.html")
    cpy_t("episode.html", "templates/episode.html")
    cpy_t("stylesheet.css", "templates/assets/stylesheet.css")
    puts "Done! Thanks for updating :)"
  end
  
  def self.cdir_p(dir)
    puts "Creating directory '#{dir}'"
    FileUtils.mkdir_p(dir)
  end
  def self.cpy_t(source, destination)
    puts "Creating file '#{destination}'"
    FileUtils.cp File.join($source_root, source), destination
  end
  
  class Episode
    def self.new_from_meta(filename, meta)
      return Episode.new(filename, meta['title'], Date.parse(meta['date']), meta['synopsis'], meta['subtitle'], meta['tags'])
    end
    def initialize(filename, title, date, synopsis, subtitle = nil, tags = [], compiledname = nil)
      @filename = filename
      @title = title
      @date = date
      @synopsis = synopsis
      @subtitle = subtitle
      @tags = tags
      @compiledname = compiledname
      
      if @compiledname.nil? or @compiledname.empty?
        @compiledname = @filename.gsub(/[^0-9A-Za-z .]/, '').gsub(' ','_')
      end
    end
    attr_accessor :filename, :title, :date, :synopsis, :tags, :subtitle, :compiledname
    def duration
      return @duration unless @duration.nil?
      length = 0
      Mp3Info.open("content/#{@filename}") do |mp3|
        length = mp3.length
      end
      length = length.to_i
      seconds = length % 60
      minutes = (length / 60).to_i
      @duration = "#{minutes}:#{seconds}"
    end
    def size
      File.size "content/#{filename}"
    end
    def keywords
      @tags.join ', ' unless @tags.nil? or @tags.empty?
    end
    def file_path(leader=true)
      return "#{leader ? "/" : ""}assets/mp3/#{@compiledname}" unless @compiledname.nil?
      return false
    end
    def file_url
      return "#{$config['urlbase']}#{file_path}" unless file_path.nil?
      return false
    end
    def path(leader=true) 
      return "#{leader ? "/" : ""}episode/#{@compiledname[0..-5]}.html" unless @compiledname.nil?
      return false
    end
    def url
      return "#{$config['urlbase']}#{path}" unless path.nil?
      return false
    end
  end

  def self.compile()
    puts "Compiling..."
    meta = YAML.load_file("content/metadata.yml")
    
    episodes     = Array.new
    filesfound   = Array.new 
    touchedfiles = Array.new
    Dir.glob('content/*.mp3') do |file|
      filename = file[8..-1]
      unless meta == false or meta[filename].nil?
        # Episode metadata already stored
        episodes   << Episode.new_from_meta(filename, meta[filename])
        filesfound << filename
      else
        # No episode metadata stored for this yet
        
        puts "Warning: no metadata found for file #{filename}"
      end
    end

    # Check for files in meta but not found
    unless meta == false
      meta.each do |file|
        next if filesfound.include? file[0]
        puts "Warning: found metadata for file #{file[0]}, but file itself is missing. Will not be published."
      end
    end
    
    # Make sure necessary directories exist
    FileUtils.mkdir_p('output/assets') unless File.directory?('output/assets')
    FileUtils.mkdir_p('output/assets/mp3') unless File.directory?('output/assets/mp3')
    FileUtils.mkdir_p('output/episode') unless File.directory?('output/episode')
    
    # Copy over (TODO: and process) MP3 files 
    episodes.each do |episode|
      FileUtils.copy "content/#{episode.filename}", "output/assets/mp3/#{episode.compiledname}"
      touchedfiles << "assets/mp3/#{episode.compiledname}"
    end
    
    # Copy over assets
    Dir.foreach("templates/assets") do |item|
      next if item == '.' or item == '..'
      begin
        FileUtils.copy "templates/assets/#{item}", "output/assets/#{item}"
        touchedfiles << "assets/#{item}"
      rescue Errno::EISDIR
        puts "Warning: subdirectories in templates/assets are ignored!"
      end
    end
   
    # Update index.html  
    layout = File.read('templates/layout.html')
    layout = Erubis::Eruby.new(layout)
    
    index_compiled = layout.result(config: $config, episodes: episodes) do
      index = Erubis::Eruby.new(File.read('templates/index.html'))
      index.result(config: $config, episodes: episodes, test: "hello, world") do |episode|
        ep = Erubis::Eruby.new(File.read('templates/episode.html'))
        ep.result(config: $config, episodes: episodes, episode: episode)
      end
    end
    File.open('output/index.html', 'w') {|f| f.write(index_compiled) }
    touchedfiles << 'index.html'
    
    # Update episode pages
    episodes.each do |episode|
      layout = File.read('templates/layout.html')
      layout = Erubis::Eruby.new(layout)
      episode_compiled = layout.result(config: $config, episodes: episodes) do
        ep = Erubis::Eruby.new(File.read('templates/episode.html'))
        ep.result(config: $config, episodes: episodes, episode: episode)
      end
      File.open("output/#{episode.path(false)}", 'w') {|f| f.write(episode_compiled) }
      touchedfiles << episode.path(false)
    end
    
    # Update iTunes RSS
    itunes = File.read "#{$source_root}/itunes.xml" # Use itunes.xml template in gem, not in site's template folder.
    itunes = Erubis::Eruby.new(itunes)
    itunes_compiled = itunes.result(config: $config, episodes: episodes)
    File.open("output/itunes.xml", 'w') {|f| f.write(itunes_compiled) }
    touchedfiles << "itunes.xml"
    
    
    # Update General RSS
    

    # Purge left over files
    purge_output(touchedfiles)
  end

  def self.purge_output(touchedfiles, subdir = "")
    Dir.foreach("output/#{subdir}") do |item|
      next if item == '.' or item == '..'
      p = "#{subdir}#{item}"
      begin
        File.delete "output/#{subdir}#{item}" unless touchedfiles.include? p
      rescue Errno::EISDIR, Errno::EPERM # Rescuing EPERM seems to be necessary on macs, hmm :/
        purge_output touchedfiles, "#{p}/"
      end  
    end
  end

  def self.deploy
    touchedfiles = Array.new  
    deploy_r touchedfiles
    
    # Purge left over files
    purge_bucket touchedfiles  
  end

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

  def link_to(name, url)
    return %Q{<a href="#{url}">#{name}</a>}
  end
