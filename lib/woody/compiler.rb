require 'preamble'

class Woody
  # Handles functions related to compiling the Woody site
  module Compiler

    # Compiles the Woody site
    def compile(options = nil)
      puts "Compiling..."
      meta = YAML.load_file(dir("content/metadata.yml"))
		
  		# instantiate the metadata hash so shit doesn't explode in our faces
      meta = Hash.new if meta == false


      posts      = Array.new
      filesfound = Array.new
      Dir.glob(dir('content/*.mp3')) do |file|
        filename = undir(file)[8..-1]
        unless meta == false or meta[filename].nil?
          # Episode metadata already stored
          posts      << Episode.new_from_meta(self, filename, meta[filename])
          filesfound << filename
        else
          # No episode metadata stored for this yet
          unless options.nil? or options.no_add == false # Seemingly backwards, I know...
            prompt_metadata(meta, posts, filesfound, filename)
          else
            puts "Warning: found media file #{filename} but no metadata. Will not be published."
          end
        end
      end

      # Process blog posts
      Dir.glob(dir('content/posts/*')) do |file|
        puts file
        filename = undir(file)[8..-1]
        puts file
        puts filename
        data = Preamble.load(file)
        meta = data[0]
        body = data[1]


        posts << Post.new(self, filename, meta['title'], meta['subtitle'], body, Date.parse(meta['date'].to_s), meta['tags'])
      end

      posts.sort_by! do |post|
        post.date
      end.reverse!

      # Check for files in meta but not found
      unless meta.empty?
        meta.each do |file|
          next if filesfound.include? file[0]
          puts "Warning: found metadata for file #{file[0]}, but file itself is missing. Will not be published."
        end
      end

      # Make sure necessary directories exist
      FileUtils.mkdir_p(dir 'output/assets') unless File.directory?(dir 'output/assets')
      FileUtils.mkdir_p(dir 'output/assets/mp3') unless File.directory?(dir 'output/assets/mp3')
      FileUtils.mkdir_p(dir 'output/post') unless File.directory?(dir 'output/post')

      # Copy over (TODO: and process) MP3 files
      posts.each do |post|
        next unless post.has_file?
        copy_file_to_output dir(File.join("content", post.filename)), File.join("assets/mp3", post.compiledname)
      end

      # Copy over assets
      copy_assets

      # Update index.html
      layout = File.read(dir 'templates/layout.html')
      layout = Erubis::Eruby.new(layout)

      index_compiled = layout.result(config: @config) do
        index = Erubis::Eruby.new(File.read(dir 'templates/index.html'))
        index.result(config: @config, posts: posts) do |post|
          ep = Erubis::Eruby.new(File.read(dir 'templates/post.html'))
          ep.result(config: @config, posts: posts, post: post)
        end
      end
      write_output_file('index.html') {|f| f.write(index_compiled) }

      # Update post pages
      posts.each do |post|
        layout = File.read(dir 'templates/layout.html')
        layout = Erubis::Eruby.new(layout)
        post_compiled = layout.result(config: @config) do
          ep = Erubis::Eruby.new(File.read(dir 'templates/post.html'))
          ep.result(config: @config, posts: posts, post: post)
        end
        write_output_file(post.path!) {|f| f.write(post_compiled) }
      end

      # Copy over iTunes.png
      begin
        copy_file_to_output "content/iTunes.png", "assets/iTunes.png"
      rescue Errno::ENOENT
        puts "Warning: content/iTunes.png missing!"
      end

      # Update (iTunes) RSS
      @config['itunes']['explicit'] = "no" if @config['itunes']['explicit'].nil?
      feedxml = File.read File.join($source_root, "feed.xml") # Use feed.xml template in gem, not in site's template folder.
      feed = Erubis::Eruby.new(feedxml)
      feed_compiled = feed.result(config: @config, posts: posts)
      write_output_file("feed.xml") {|f| f.write(feed_compiled) }


      # Purge left over files
      purge_output

      # Remove all empty directories from the output
      Dir[dir 'output/**/*'].select { |d| File.directory? d }.select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }.each { |d| Dir.rmdir d }
    end

    private

    # Prompts for metadata for new media files
    def prompt_metadata(meta, posts, filesfound, filename)
      puts "Found new media file: #{filename}"
      if agree("Add metadata for this file? ")
        m = Hash.new
        m['date']     = Time.now
        m['title']    = ask "Title: "
        m['subtitle'] = ask "Subtitle: "
        m['synopsis'] = ask "Synopsis:"
        m['tags']     = ask "Tags: ", Array
        m['explicit'] = agree "Explicit content?: "
        
        meta[filename] = m
        posts << Episode.new(self, filename,  m['title'], Date.parse(m['date'].to_s), m['synopsis'], m['subtitle'], m['tags'], m['explicit'])
        filesfound << filename

        write_meta meta
        puts "Saved."
      end
      puts # Leave a blank line
    end

    # Writes the metadata file
    def write_meta(meta)
      File.open(dir('content/metadata.yml'), 'w' ) do |out|
        YAML.dump meta, out
      end
    end

    # Safely copies files to the output directory
    def copy_file_to_output(source, destination)
      d = dir(File.join("output", destination))
      FileUtils.copy source, d
      @touchedfiles << undir(d)
    end

    # Safely writes files to the output directory
    def write_output_file(filename, &block)
      file = dir(File.join("output", filename))
      File.open(file, 'w') do |f|
        yield f
      end
      @touchedfiles << undir(file)
    end


    # Copies custom assets to output
    def copy_assets
      Dir.glob dir("templates/assets/**/*") do |item|
        next if File.directory? item
        d = undir item
        d = d[10..-1] # Cut off "templates/" at beginning
        copy_file_to_output item, d
      end
    end

    # Deletes old files from the site's output directory
    def purge_output
      Dir.glob dir("output/**/*") do |item|
        next if File.directory? item
        File.delete item unless @touchedfiles.include? undir(item)
      end
    end

  end
end