module Woody
  # Represents an episode of the podcast
  class Episode
    # Creates a new Episode object from segment of metadata.yml
    # @param  [String] filename specifies the name of the MP3 file
    # @param  [Hash] meta is the relevant part of metadata.yml
    # @return [Episode] the new Episode object
    def self.new_from_meta(filename, meta)
      return Episode.new(filename, meta['title'], Date.parse(meta['date'].to_s), meta['synopsis'], meta['subtitle'], meta['tags'], meta['explicit'])
    end

    # Creates a new Episode object
    # @param  [String] filename specifies the name of the MP3 file
    # @param  [String] title specifies the episode's title
    # @param  [Date]   date specifies the episode's published date
    # @param  [String] synopsis specifies the episode's synopsis
    # @param  [String] subtitle specifies the episode's subtitle
    # @param  [Array]  tags specifies the episode's tags - each element is a String
    # @return [Episode] the new Episode object
    def initialize(filename, title, date, synopsis, subtitle = nil, tags = [], explicit = false)
      @filename = filename
      @title = title
      @date = date
      @synopsis = synopsis
      @subtitle = subtitle
      @tags = tags
      @explicit = explicit
      @compiledname = @filename.gsub(/[^0-9A-Za-z .]/, '').gsub(' ', '_')
    end

    attr_accessor :filename, :title, :date, :synopsis, :tags, :subtitle, :explicit, :compiledname

    # @return the episode's page URL where possible, otherwise false
    def url
      return "#{$config['urlbase']}#{path}" unless path == false
      return false
    end

    # @return the episode's page path where possible, otherwise false
    def path(leader=true)
      return "#{leader ? "/" : ""}episode/#{@compiledname[0..-5]}.html" unless @compiledname.nil?
      return false
    end

    # @return the episode's media file URL where possible, otherwise false
    def file_url
      return "#{$config['urlbase']}#{file_path}" unless file_path == false
      return false
    end

    # @return the episode's media file path where possible, otherwise false
    def file_path(leader=true)
      return "#{leader ? "/" : ""}assets/mp3/#{@compiledname}" unless @compiledname.nil?
      return false
    end

    # @return [String] a comma separated list of tags, or nil if no tags
    def keywords
      @tags.join ', ' unless @tags.nil? or @tags.empty?
    end

    # @return [Integer] the size of the episodes media file in bytes
    def size
      File.size "content/#{filename}"
    end
   
    # @return [String] 'yes' if explicit content, otherwise n'o'
    def explicit_string 
      @explicit ? 'yes' : 'no'
    end
    
    # @return [String] the duration of the media file, formatted as minutes:seconds
    def duration
      return @duration unless @duration.nil?
      length = 0
      Mp3Info.open("content/#{@filename}") do |mp3|
        length = mp3.length
      end
      @duration = Time.at(length).gmtime.strftime('%R:%S') # Should work up to 24 hours
      if @duration.start_with? "00:"
        @duration = @duration[3..-1]
      end
    end

  end
end
