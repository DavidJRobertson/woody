module Woody
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
        @compiledname = @filename.gsub(/[^0-9A-Za-z .]/, '').gsub(' ', '_')
      end
    end

    attr_accessor :filename, :title, :date, :synopsis, :tags, :subtitle, :compiledname

    def url
      return "#{$config['urlbase']}#{path}" unless path.nil?
      return false
    end

    def path(leader=true)
      return "#{leader ? "/" : ""}episode/#{@compiledname[0..-5]}.html" unless @compiledname.nil?
      return false
    end

    def file_url
      return "#{$config['urlbase']}#{file_path}" unless file_path.nil?
      return false
    end

    def file_path(leader=true)
      return "#{leader ? "/" : ""}assets/mp3/#{@compiledname}" unless @compiledname.nil?
      return false
    end

    def keywords
      @tags.join ', ' unless @tags.nil? or @tags.empty?
    end

    def size
      File.size "content/#{filename}"
    end

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

  end
end
