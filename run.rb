#!/usr/bin/env ruby

require 'yaml'

albums = YAML.load_file("#{ENV["HOME"]}/.icloud-albums.yml")

puts "Beginning #{albums["albums"].length} albums..."

albums["albums"].each do |a|
				puts "Downloading album #{a["name"]}:"
				system "./download_album.rb #{a["id"]}"
				puts "Done with that album!"
				sleep 5
end

