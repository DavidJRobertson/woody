require "woody/version"
require "woody/post"
require "woody/episode"
require "woody/compiler"
require "woody/deployer"
require "woody/generator"

require 'yaml'
require 'erubis'
require 'aws/s3'
require 'digest'
require 'fileutils'
require 'uri'
require 'date'
require 'time'
require 'highline/import'

oldverbosity = $VERBOSE; $VERBOSE = nil # Silence depreciation notice
require 'mp3info'
$VERBOSE = oldverbosity

# Woody podcast static site generator
module Woody
  # Path of template directory inside gem
  $source_root = File.expand_path("../../templates", __FILE__)

  # Load configuration and connect to S3
  def self.init
    begin
      $config = YAML.load_file("woody-config.yml")
    rescue Errno::ENOENT
      puts "This doesn't look like a valid Woody site directory!"
      exit!
    end

    # Strip trailing slash from urlbase, if present.
    if $config['urlbase'].end_with? "/"
      $config['urlbase'] = $config['urlbase'][0..-2]
    end

    if $config['distributiontype'] == "s3"
      prefix = $config['s3']['prefix']
      unless prefix.nil?
        $config['urlbase'] = $config['urlbase'] + "/" + prefix
      end
    end

    options = { 
      :access_key_id     => $config['s3']['accesskey']['id'], 
      :secret_access_key => $config['s3']['accesskey']['secret']
    }
    
    unless ENV['http_proxy'].nil?
      uri = URI(ENV['http_proxy'])
      p = Hash.new
      p[:host]     = uri.host
      p[:port]     = uri.port
      p[:user]     = uri.user     unless uri.user.nil?
      p[:password] = uri.password unless uri.password.nil?
      options[:proxy] = p 
    end
    
    AWS::S3::Base.establish_connection!(options)
    AWS::S3::DEFAULT_HOST.replace $config['s3']['hostname']
    $bucketname = $config['s3']['bucket']  
  end

end


# Generates HTML hyperlink/anchor tag
# @param  [String] text specifies text to display for link
# @param  [String] url specifies URL/path to link to
# @return [String] generated HTML anchor tag (hyperlink)
def link_to(text, url)
  return %Q{<a href="#{url}">#{text}</a>}
end

# @return HTML meta generator tag with Woody attribution and version
def generator_meta_tag()
  return %Q{<meta name="generator" content="Woody #{Woody::VERSION}" />}
end
