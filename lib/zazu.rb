require 'colorize'
require 'etc'
require 'fileutils'
require 'logger'
require 'net/https'
require 'open3'
require 'thread'
require 'tmpdir'
require 'uri'

# Fetch tools and run them
#
# Example:
# 
#   zazu = Zazu.new 'my-script'
#   zazu.fetch url: 'https://example.com/my_script.sh'
#   zazu.run ['--environment', 'prod']
#
class Zazu
  VERSION = '0.0.2'

  class Error < Exception; end
  class DownloadError < Error; end
  class RunError < Error; end

  attr_reader :name, :path

  # Creates the Zazu instance. Create as many as you like.
  #
  # * +:name:+ - The name of the command
  # * +:logger:+ - Default to STDERR, can be replaced with another, e.g. IO::NIL
  # * +:level:+ - Log level for the logger
  def initialize(name, logger: Logger.new(STDERR), level: Logger::INFO)
    @name = name
    @path = File.join Dir.tmpdir, name + '-download'
    @logger = logger
    @logger.level = level
  end

  # Download the tool, to the temp directory
  # * +:url:+ - The URL to the tool--Optional, can specity the block instead
  # * +:age:+ - Seconds old the downloaded copy can be before downloading again--Default is 3600
  # * +:block:+ - Receives the OS (:linux, :mac, :windows) and the machine arch (32 or 64)--Should return the URL
  def fetch(url: nil, age: 60*60, &block)
    return false if File.exists?(path) && Time.now - File.stat(path).mtime < age

    url ||= block.call os, arch
    @logger.info "Downloading from #{url}".cyan

    download_file url
  end

  # Run the downloaded tool with arguments
  # * +:args:+ - An array of args for the command
  # * +:show:+ - A regexp of output (STDOUT and STDERR) to include
  # * +:hide:+ - A regexp of output (STDOUT and STDERR) to exclude
  # * +:block:+ - If given, receies each output line, otherwise output is logged
  def run(args = [], show: //, hide: /^$/, &block) 
    command = [path] + args
    @logger.debug "Running command #{command}".yellow
    Open3.popen3 *command do |i,o,e,t|
      i.close

      threads = [o,e].map do |x|
        Thread.new do
          x.each_line do |line|
            line.chomp!
            next if line !~ show || line =~ hide

            if block
              block.call line
            else
              @logger.info line.cyan
            end
          end
        end
      end

      threads.each &:join
      t.join

      raise RunError.new "#{path} exited with code #{t.value}" unless t.value == 0
    end

    true
  end

  private

  def download_file(url)
    uri = URI url
    res = Net::HTTP.start uri.host, uri.port, use_ssl: uri.scheme == 'https' do |http|
      http.request Net::HTTP::Get.new uri do |res|
        if res.is_a?(Net::HTTPOK)
          @logger.debug "Opening file #{path}".yellow
          File.open path, 'wb' do |file|
            res.read_body do |chunk|
              file.write chunk
            end
          end
          @logger.debug "Closed file #{path}".yellow
          FileUtils.chmod 0755, path
        end
      end
    end

    case res
    when Net::HTTPOK
      true
    when Net::HTTPRedirection
      @logger.debug "Following redirect #{res['Location']}"
      download_file res['Location']
    else
      raise DownloadError.new "Error downloading #{url}, got #{res}"
    end
  end

  def os
    case Etc.uname[:sysname]
    when /linux/i
      :linux
    when /darwin/i
      :mac
    when /windows/i
      :windows
    end
  end

  def arch
    Etc.uname[:machine] =~ /x(86_)?64/ ? 64 : 32
  end
end
