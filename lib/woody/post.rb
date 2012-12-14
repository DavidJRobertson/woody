module Woody
  # Represents a post
  class Post
    # Creates a new Post object
    # @param  [String] filename specifies the name of the post file
    # @param  [String] title specifies the Post's title
    # @param  [String] subtitle specifies the Post's subtitle
    # @param  [String] body specifies the Post's body
    # @param  [Date]   date specifies the Post's published date
    # @param  [Array]  tags specifies the Post's tags - each element is a String
    # @return [Post] the new Post object
    def initialize(filename, title, subtitle, body, date, tags = [], compiledname = nil)
      @filename = filename
      @title = title
      @subtitle = subtitle
      @body = body
      @date = date
      @tags = tags.nil? ? [] : tags
      @compiledname = @filename.gsub(/[^0-9A-Za-z .]/, '').gsub(' ', '_')
    end
    attr_accessor :filename, :title, :subtitle, :body, :date, :tags, :compiledname

    # @return the Page's page URL where possible, otherwise false
    def url
      return "#{$config['urlbase']}#{path!}" unless path! == false
      return false
    end

    # @return the Page's page path where possible, otherwise false. Does not take prefix in to account.
    def path!(leader=true)
      return "#{leader ? "/" : ""}post/#{@compiledname.chomp(File.extname(@compiledname))}.html" unless @compiledname.nil?
      return false
    end

    # @return the Page's page path where possible, otherwise false. Includes the site prefix if enabled.
    def path(leader=true)
      prefix = $config['s3']['prefix']
      return "#{leader ? "/" : ""}#{prefix.nil? ? "" : prefix + "/" }post/#{@compiledname.chomp(File.extname(@compiledname))}.html" unless @compiledname.nil?
      return false
    end

    # @return [String] a comma separated list of tags, or nil if no tags
    def keywords
      @tags.join ', ' unless @tags.nil? or @tags.empty?
    end

    def has_file?
      false
    end

    def <=> (other)
      other.date <=> self.date
    end
  end
end