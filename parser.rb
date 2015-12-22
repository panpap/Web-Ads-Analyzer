require 'optparse'
require 'utilities'
require 'ops'

start = Time.now


OptionParser.new { |opts|
  opts.banner = "Usage: #{File.basename($0)} [-p -s -a -h] [-f <Search_string>] [-t <time_window>] [filename (optional)]"

  opts.on( '-s', '--separate', 'Separate fields to files. Produced files are stored in ./data/ folder') do
	ops=Operations.new(ARGV[0])
    ops.loadFile()
    ops.separate
  end

  opts.on('-p', '--parse', 'Parse and analyze dataset.') do
	ops=Operations.new(ARGV[0])
    ops.loadFile()
    ops.stripURL
  end	
	
  opts.on('-f', '--find STRING', 'Search particular string in the dataset.') do |str|
	ops=Operations.new(ARGV[0])
    ops.loadFile()
    ops.findStrInRows(str,true)
  end

  opts.on('-a', '--all', 'Load dataset, separate parameters, detect ads') do
	ops=Operations.new(ARGV[0])
    ops.loadFile()
    ops.separate
    ops.stripURL
  end

  opts.on('-t', '--timelines STRING', 'Make user Timelines per N seconds') do |sec|
	path=ARGV[0].split("/")[0].split("results_")[1]
	s=""
	lastChar=path[path.size-1]
	if Utilities.is_numeric?(lastChar)
	s=path.delete(lastChar)
	ops=Operations.new(s)
	ops.makeTimelines(sec,ARGV[0])
  end

}.parse!
finish = Time.now
puts "Total Elapsed time "+(finish - start).to_s+" seconds"
