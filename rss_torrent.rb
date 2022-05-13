require 'json'
require 'rss'
require 'open-uri'
require 'time'
# Including resolv-replace to fix some networking issues
# https://stackoverflow.com/questions/9939726/ruby-net-http-opening-connection-very-slow/27485369#27485369
# https://github.com/ruby/ruby/pull/597#issuecomment-40507119
require 'resolv-replace' 

VERBOSE = ARGV.include?("--verbose") || ARGV.include?("-v")
TIMESTAMPS = if File.exist? File.dirname(__FILE__) + '/timestamps.json'
               JSON.parse(File.read(File.dirname(__FILE__) + '/timestamps.json'))
             else
               {}
             end
RULES = JSON.parse(File.read(File.dirname(__FILE__) + '/rules.json')).freeze
DOWNLOAD_TO = '/storage/gondolin/Plex/Anime'.freeze

def download(url, folder)
  # puts "transmission-remote -n user:[REDACTED] -w \"#{DOWNLOAD_TO}/#{folder}\" -a \"#{url}\""
  `transmission-remote -n 'USER:PASS' -w "#{DOWNLOAD_TO}/#{folder}" -a "#{url}"`
end

def downloaded?(folder, item)
  !TIMESTAMPS[folder].nil? && item.pubDate < Time.iso8601(TIMESTAMPS[folder])
end

puts "Processing rules..." if VERBOSE
RULES.each do |folder, url|
  puts "Processing #{folder}..." if VERBOSE
  puts "Opening #{url}..." if VERBOSE
  open(url) do |rss|
    puts "Parsing..." if VERBOSE
    feed = RSS::Parser.parse(rss)
    feed.items.each do |item|
      puts "Downloading #{item.link}..." if VERBOSE && !downloaded?(folder, item)
      download(item.link, folder) unless downloaded?(folder, item)
    end
  end
  puts "" if VERBOSE
end

puts "Saving timestamps..." if VERBOSE
new_timestamps = (RULES.keys.map {|folder| [folder, Time.now.iso8601]}).to_h
File.write(File.dirname(__FILE__) + '/timestamps.json', JSON.generate(new_timestamps))
puts "Saved timestamps" if VERBOSE
