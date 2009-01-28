require 'fileutils'

puts "Installing InPlaceJQueryTimepickr"

FileUtils.copy(Dir[File.dirname(__FILE__) + '/public/javascripts/*.js'], File.dirname(__FILE__) + '/../../../public/javascripts/')
FileUtils.copy(Dir[File.dirname(__FILE__) + '/public/stylesheets/*.css'], File.dirname(__FILE__) + '/../../../public/stylesheets/')

puts "Done installing InPlaceJQueryTimepickr"
