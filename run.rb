# require 'rubygems'
require 'selenium-webdriver'
require 'byebug'
require 'parallel'
require 'fileutils'

MAX_DOWNLOADING_FILES = 6

def downloading_files
  Dir.glob(ENV['HOME'] + "/Downloads/HYFY*.crdownload")
end

def delete_downloaded_files!
  downloading_files.each do |file|
    puts "file: #{file}"
    FileUtils.rm_rf(file)
  end
end

# load the config
auth_variables = {}
f = File.read("auth")
f.split("\n").each do |line|
  key, value = line.split("=")
  key.strip!
  value.strip!
  auth_variables[key] = value
end

# delete old downloaded files
delete_downloaded_files!

# the webdriver...

driver = Selenium::WebDriver.for(:chrome)

driver.navigate.to "https://app.hyfy.io/accounts/login/?logout=1"
driver.find_element(:css, ".google").click

driver.find_element(:css, "input[type='email']").send_keys(auth_variables["EMAIL"])
driver.find_element(:css, "#identifierNext").click

sleep 2

driver.find_element(:css, "input[type='password']").send_keys(auth_variables["PASSWORD"])
driver.find_element(:css, "#passwordNext").click

sleep 2

SEARCH_KEYS = auth_variables["SEARCH_KEYS"]

driver.find_element(:css, ".js-search-input").send_keys(SEARCH_KEYS)
driver.find_element(:css, ".js-search-input").send_keys(:return)

sleep 2

elements = driver.find_elements(:css, ".card.video-lib-item")
length = elements.length
0.upto(length-1) do |index|
  while downloading_files.length >= MAX_DOWNLOADING_FILES
    puts "* hit max downloading files, sleeping..."
    sleep 5
  end

  element = driver.find_elements(:css, ".card.video-lib-item")[index]
  sleep 1
  driver.action.move_to(element).perform
  sleep 1
  driver.find_elements(:css, ".video-overlay-options .tooltip")[index].click
  sleep 1
  driver.find_elements(:css, ".js-library-download-video")[index].click
  sleep 3
end

# debugger
puts "DONE!, but sleeping, waiting for all downloads to finish!"
sleep 60*60*2 # sleep for a really long time 
puts "DONE!"

driver.quit
