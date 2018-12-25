#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'fileutils'
require 'yaml'

album_name = ARGV[0]
raise "Must provide album search term" if album_name == nil

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])
#options = Selenium::WebDriver::Chrome::Options.new
driver = Selenium::WebDriver.for(:chrome, options: options)
dir = "/home/pi/StockPhotos/#{album_name}"
FileUtils.mkdir_p(dir)
urls_seen = Set.new
files_seen = Set.new

driver.get("https://www.pexels.com/search/#{album_name}/")

puts "  Navigated to index page: #{driver.current_url}"

sleep 2

c = 0
items_found = 1

while true
elems = driver.find_elements(css: "img.photo-item__img[data-big-src]")
items_found = elems.length
break if items_found <= c
puts "  Found #{items_found}"
elems.each do |elem|
	begin
	src = elem["data-big-src"]
		puts "    Downloading image #{c}: #{src}"
		u = URI.parse(src)
		filename = u.path.split("/").last.downcase
		path = "#{dir}/#{filename}"

		if File.exist?(path)
				puts "    Skipping already downloaded file #{path}"
		else
			r = Net::HTTP.get_response(u)
			puts "  #{r.inspect}"
			File.write(path, r.body)
			puts "    Wrote file of length #{r.body.length} to #{path}"	
		end
		c += 1
	rescue => e
		puts "Error: #{e.inspect}"
	end
end

break # just do 1 page for now

puts "  Scrolling to bottom"
driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
sleep 5
end


puts "  Finished #{c} photos in album #{album_name}!"
driver.quit

