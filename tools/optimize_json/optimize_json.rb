#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'json'
require 'zip'

script_name = File.basename(__FILE__)

options = OpenStruct.new
parser = OptionParser.new do |opt|
  opt.banner = "Usage: #{script_name} [options] input_file [output_file]"
  opt.separator ""
  opt.separator "Common options:"
  opt.on('-z', '--zip', "Zip output file") { |o| options.zip = true }
  opt.on('-p', '--prettify', "Prettify output file") { |o| options.prettify = true }
  opt.on('-h', '--help', "Show this message") { puts opt; exit }
end
parser.parse!

if ARGV.count < 1
  puts parser
  exit
end

input_file  = ARGV[0]
output_file = if ARGV.count > 1 then ARGV[1] else input_file end

if !File.file?(input_file)
  puts "File not found: #{input_file}"
  exit
end

class String
  def add_path(suffix)
    return self + "/" + suffix.to_s
  end
end

def process(object, path)

  if object.instance_of? Array
    clone = []
    object.each_index do |i|
      clone[i] = process(object[i], path.add_path(i))
    end

    if path.end_with? "Frames" and clone.count > 1
      compressed_frames = [clone[0]]
      (1...clone.count).each do |frame_index|
        prev_frame = compressed_frames.last
        next_frame = clone[frame_index]
        if (prev_frame['elements'].count == 0 and next_frame['elements'].count == 0 and !next_frame.has_key?('name'))
          prev_frame['duration'] += next_frame['duration']
        else
          compressed_frames << next_frame
        end
      end
      clone = compressed_frames
    end

  elsif object.instance_of? Hash
    clone = {}
    object.each_key do |k|
      if k != "DecomposedMatrix"
        clone[k] = process(object[k], path.add_path(k))
      end
    end
  else
    clone = object
  end

  return clone
end

animation = JSON.parse(File.read(input_file))

result = process(animation, "")
json = options.prettify ? JSON.pretty_generate(result) : result.to_json

if options.zip
  output_file = "#{output_file}.zip" if !output_file.downcase.end_with?('.zip')
  Zip::File.open(output_file, Zip::File::CREATE) do |zipfile|
    zipfile.get_output_stream('Animation.json') { |f| f << json }
  end
else
  File.open(output_file, 'w') { |f| f << json }
end
