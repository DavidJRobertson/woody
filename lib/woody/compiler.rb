module Woody
  # Handles functions related to compiling the Woody site
  module Compiler
    @@touchedfiles = []

    # Compiles the Woody site
    def self.compile(options = [])
      puts "Compiling..."
      meta = YAML.load_file("content/metadata.yml")
		
  		# instantiate the metadata hash so shit doesn't explode in our faces
			meta = Hash.new if meta.empty?


      episodes     = Array.new
      filesfound   = Array.new
      Dir.glob('content/*.mp3') do |file|
        filename = file[8..-1]
        unless meta == false or meta[filename].nil?
          # Episode metadata already stored
          episodes   << Episode.new_from_meta(filename, meta[filename])
          filesfound << filename
        else
          # No episode metadata stored for this yet
          unless options.no_add == false # Seemingly backwards, I know...
            prompt_metadata(meta, episodes, filesfound, filename)
          else
            puts "Warning: found media file #{filename} but no metadata. Will not be published."
          end
        end
      end


      # Check for files in meta but not found
      unless meta.empty?
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
        copy_file_to_output File.join("content", episode.filename), File.join("assets/mp3", episode.compiledname)
      end

      # Copy over assets
      copy_assets

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
      write_output_file('index.html') {|f| f.write(index_compiled) }

      # Update episode pages
      episodes.each do |episode|
        layout = File.read('templates/layout.html')
        layout = Erubis::Eruby.new(layout)
        episode_compiled = layout.result(config: $config, episodes: episodes) do
          ep = Erubis::Eruby.new(File.read('templates/episode.html'))
          ep.result(config: $config, episodes: episodes, episode: episode)
        end
        write_output_file(episode.path) {|f| f.write(episode_compiled) }
      end

      # Copy over iTunes.png
      begin
        copy_file_to_output "content/iTunes.png", "assets/iTunes.png"
      rescue Errno::ENOENT
        puts "Warning: content/iTunes.png missing!"
      end

      # Update iTunes RSS
      $config['itunes']['explicit'] = "no" if $config['itunes']['explicit'].nil?
      itunes = File.read "#{$source_root}/itunes.xml" # Use itunes.xml template in gem, not in site's template folder.
      itunes = Erubis::Eruby.new(itunes)
      itunes_compiled = itunes.result(config: $config, episodes: episodes)
      write_output_file("itunes.xml") {|f| f.write(itunes_compiled) }



      # TODO: Update General RSS


      # Purge left over files
      purge_output

      # Remove all empty directories from the output
      Dir['output/**/*'].select { |d| File.directory? d }.select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }.each { |d| Dir.rmdir d }
    end

    private

    # Safely copies files to the output directory
    def self.copy_file_to_output(source, destination)
      d = File.join("output", destination)
      FileUtils.copy source, d
      @@touchedfiles << d
    end

    # Safely writes files to the output directory
    def self.write_output_file(filename, &block)
      file = File.join("output", filename)
      File.open(file, 'w') do |f|
        yield f
      end
      @@touchedfiles << file
    end

    # Prompts for metadata for new media files
    def self.prompt_metadata(meta, episodes, filesfound, filename)
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
        episodes << Episode.new(filename,  m['title'], Date.parse(m['date'].to_s), m['synopsis'], m['subtitle'], m['tags'], m['explicit'])
        filesfound << filename

        write_meta meta
        puts "Saved."
      end
      puts # Leave a blank line
    end

    # Writes the metadata file
    def self.write_meta(meta)
      File.open( 'content/metadata.yml', 'w' ) do |out|
        YAML.dump meta, out
      end
    end

    # Copies custom assets to output
    def self.copy_assets
      Dir.glob "templates/assets/**/*" do |item|
        next if File.directory? item
        d = item[10..-1] # Cut off "templates/" at beginning
        copy_file_to_output item, d
      end
    end


    # Deletes old files from the site's output directory
    def self.purge_output
      Dir.glob "output/**/*" do |item|
        next if File.directory? item
        File.delete item unless @@touchedfiles.include? item
      end
    end

  end
end