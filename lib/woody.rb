require "woody/version"
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

oldverbosity = $VERBOSE; $VERBOSE = nil # Silence depreciation notice
require 'mp3info'
$VERBOSE = oldverbosity


module Woody
  $source_root = File.expand_path("../../templates", __FILE__)
  # Load configuration
  def self.init
    begin
      $config = YAML.load_file("woody-config.yml")
    rescue Errno::ENOENT
      puts "This doesn't look like a valid Woody site directory!"
      return
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

def link_to(name, url)
  return %Q{<a href="#{url}">#{name}</a>}
end

def generator_meta_tag()
  return %Q{<meta name="generator" content="Woody #{Woody::VERSION}" />}
end
