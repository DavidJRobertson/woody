require "woody/post"

class Woody
  # Represents an episode of the podcast. Inherits from Post.
  class Episode < Post
    # Creates a new Episode object from segment of metadata.yml
    # @param  [String] filename specifies the name of the MP3 file
    # @param  [Hash] meta is the relevant part of metadata.yml
    # @return [Episode] the new Episode object
    def self.new_from_meta(site, filename, meta)
      return Episode.new(site, filename, meta['title'], Date.parse(meta['date'].to_s), meta['synopsis'], meta['subtitle'], meta['tags'], meta['explicit'])
    end

    # Creates a new Episode object
    # @param  [String] filename specifies the name of the MP3 file
    # @param  [String] title specifies the episode's title
    # @param  [Date]   date specifies the episode's published date
    # @param  [String] body specifies the episode's synopsis/body
    # @param  [String] subtitle specifies the episode's subtitle
    # @param  [Array]  tags specifies the episode's tags - each element is a String
    # @return [Episode] the new Episode object
    def initialize(site, filename, title, date, raw_body, subtitle = nil, tags = [], explicit = false)
      super site, filename, title, subtitle, raw_body, date, tags
      @explicit = explicit
      @compiledname = @filename.gsub(/[^0-9A-Za-z ._]/, '').gsub(' ', '_')
    end

    attr_accessor :explicit


    # @return the episode's media file URL where possible, otherwise false
    def file_url
      return "#{@site.config['urlbase']}#{file_path!}" unless file_path! == false
      return false
    end

    # @return the episode's media file path! where possible, otherwise false. Does not take prefix in to account.
    def file_path!(leader=true)
      return "#{leader ? "/" : ""}assets/mp3/#{@compiledname}" unless @compiledname.nil?
      return false
    end

    # @return the episode's media file path! where possible, otherwise false. Includes site prefix if enabled.
    def file_path(leader=true)
      prefix = @site.config['s3']['prefix']
      return "#{leader ? "/" : ""}#{prefix.nil? ? "" : prefix + "/" }assets/mp3/#{@compiledname}" unless @compiledname.nil?
      return false
    end



    # @return [Integer] the size of the episodes media file in bytes
    def size
      File.size File.join("content", filename)
    end
   
    # @return [String] 'yes' if explicit content, otherwise 'no'
    def explicit_string 
      @explicit ? 'yes' : 'no'
    end
    
    # @return [String] the duration of the media file, formatted as minutes:seconds
    def duration
      return @duration unless @duration.nil?
      length = 0
      Mp3Info.open(File.join("content", filename)) do |mp3|
        length = mp3.length
      end
      @duration = Time.at(length).gmtime.strftime('%R:%S') # Should work up to 24 hours
      if @duration.start_with? "00:"
        @duration = @duration[3..-1]
      end
    end


    def has_file?
      true
    end

  end
end
