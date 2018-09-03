#!/usr/bin/env ruby

require 'selenium-webdriver'
require 'fileutils'
require 'yaml'

album_name = ARGV[0]

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])
driver = Selenium::WebDriver.for(:chrome, options: options)
puts "Downloading album ID #{album_name}:"
dir = "/home/pi/Pictures/#{album_name}"
movies_dir = "/home/pi/Videos"
FileUtils.mkdir_p(dir)
urls_seen = Set.new
files_seen = Set.new

driver.get("https://www.icloud.com/sharedalbum/##{album_name}")

puts "  Navigated to index page: #{driver.current_url}"

sleep 2

driver.find_element(css: "[role=button]").click

sleep 5

c = 0
current_url = driver.current_url 
seen_first = false
exit_early = false
until urls_seen.include?(current_url) or c >= 200 or exit_early do
	retries = 0
	begin
		current_url = driver.current_url 
		puts "  Navigated to: #{current_url}"
		urls_seen.add(current_url)
		i = driver.find_element(css: "img")
		puts "    Downloading image #{c}: #{i["src"]}"
		u = URI.parse(i["src"])
		ext = u.path.split(".").last.downcase
		filename = "#{current_url.split(";").last}.#{ext}".downcase
		path = "#{dir}/#{filename}"

		if File.exist?(path)
			if c == 0
				seen_first = true 
				puts "    Already seen first image, going backwards now"
			elsif seen_first and c == 1
				exit_early = true
				puts "    Already seen last image, we're probably done!"
			else
				puts "    Skipping already downloaded file #{path}"
			end
		else
			r = Net::HTTP.get_response(u)
			puts "  #{r.inspect}"
			tmp_path = "/tmp/img.#{ext}"
			File.write(tmp_path, r.body)
			puts "    Wrote file of length #{r.body.length} to #{tmp_path}"	
			cmd = "convert #{tmp_path} -resize 1800x1800\\> #{path}"
			puts "    Running #{cmd}..."
			system cmd 
			puts "    Resized to #{File.stat(path).size} bytes in final location #{path}" 

			videos = driver.find_elements(css: ".play-button")
			if videos.length > 0
				puts "    Found video!!!"
				videos.first.click
				video_src = driver.find_element(css: "video > source")["src"]
				u = URI.parse(video_src)
				ext = u.path.split(".").last.downcase
				filename = "#{current_url.split("#").last.gsub(";", "_")}.#{ext}".downcase
				path = "#{movies_dir}/#{filename}"
				puts "    Downloading from #{video_src} to #{path}"
				driver.navigate.refresh
				r = Net::HTTP.get_response(u)
				File.write(path, r.body)
				puts "    Wrote #{r.body.length} bytes of video to #{path}"
			end
		end
		c += 1
		sleep 1
		driver.find_element(css: "body").send_keys(seen_first ? :arrow_left : :arrow_right)
		sleep 1
		current_url = driver.current_url 
	rescue => e
		puts "Error: #{e.inspect}"
		retries += 1
		if retries < 4
			driver.quit rescue nil
			puts "RETRY ##{retries}"
			system "pkill -f chromedriver"
			driver = Selenium::WebDriver.for(:chrome, options: options)
			driver.get(current_url)
			sleep 5
			retry
		end
	end
end

puts "  Finished #{c} photos in album #{album_name}!"
driver.quit

