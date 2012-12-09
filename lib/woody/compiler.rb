module Woody
  # Handles functions related to compiling the Woody site
  module Compiler

    # Compiles the Woody site
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
      copy_assets_r touchedfiles

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

      # Copy over iTunes.png
      if File.exist? "content/iTunes.png"
        FileUtils.copy "content/iTunes.png", "output/assets/iTunes.png"
        touchedfiles << "assets/iTunes.png"
      else
        puts "Warning: content/iTunes.png missing!"
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

      # Remove all empty directories from the output
      Dir['output/**/*'].select { |d| File.directory? d }.select { |d| (Dir.entries(d) - %w[ . .. ]).empty? }.each { |d| Dir.rmdir d }
    end

    private

    # Copies custom assets to output recursively
    def self.copy_assets_r(touchedfiles, subdir="")
      Dir.foreach("templates/assets/#{subdir}") do |item|
        next if item == '.' or item == '..'
        unless File.directory?("templates/assets/#{subdir}#{item}")
          FileUtils.copy "templates/assets/#{subdir}#{item}", "output/assets/#{subdir}#{item}"
          touchedfiles << "assets/#{subdir}#{item}"
        else
          FileUtils.mkdir_p "output/assets/#{subdir}#{item}"
          copy_assets_r touchedfiles, "#{subdir}#{item}/"
        end
      end
    end

    # Deletes old files from the site's output directory
    # @param [Array]  touchedfiles specifies which files to keep
    # @param [String] subdir specifies a subdirectory of output/ to work in (used for recursion)
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
  end
end