load 'define.rb'
load 'core.rb'
load 'plotter.rb'
require 'digest/sha1'

class Operations
	
	def initialize(filename)
		@defines=Defines.new(filename)
		@options=Utilities.loadOptions(@defines.files['configFile'])
		@func=Core.new(@defines,@options)
	end

	def countDuplicates()
		uniq=""
		total=""
		if @options['excludeCol']!=nil
			IO.popen("awk '{$"+@options['excludeCol'].to_s+"=\"\"; print $0}' "+@defines.traceFile+" | sort -u | wc -l") { |io| uniq=io.gets.split(" ")[0] }
			#awk 'NR == 1; NR > 1 {print $0 | "sort -uk1,3"}' trace > Sorted_trace
		else
			IO.popen("sort -u "+@defines.traceFile+" | wc -l") { |io| uniq=io.gets.split(" ")[0] }			
			#awk 'NR == 1; NR > 1 {print $0 | "sort -u"}' trace > Sorted_trace
		end
		IO.popen("wc -l "+@defines.traceFile) { |io| total=io.gets.split(" ")[0] }
		if (total.to_i-uniq.to_i)>0
			puts "> "+(total.to_i-uniq.to_i).to_s+" ("+(100-(uniq.to_f*100/total.to_f)).round(2).to_s+"%) dublicates were found in the trace"
		end
	end

	def dispatcher(function,str)	
		@func.makeDirsFiles
		puts "> Loading Trace... "+@defines.traceFile
		count=0
		atts=["IPport", "uIP", "url", "ua", "host", "tmstp", "status", "length", "dataSz", "dur"]		
		f=Hash.new
		File.foreach(@defines.traceFile) {|line|
			if count==0		# HEADER
				#atts=@options['headers']
				if function==1 or function==0
					atts.each{|a| f[a]=File.new(@defines.dirs['dataDir']+a,'w') if File.size?(@defines.dirs['dataDir']+a)==nil and (a!='url') and (a!="tmstp") }
				end
			else
				row=Format.columnsFormat(line,@defines.column_Format,@options)
				if row['host'].size>1 and row['host'].count('.')>0
					if function==1 or function==0
						atts.each{|att| (f[att].puts row[att]) if (att!='url' and att!="tmstp") and f[att]!=nil}
						Utilities.separateTimelineEvents(row,@defines.dirs['userDir']+row['IPport'],@defines.column_Format)
					end					
					if function==2 or function==0
						@func.parseRequest(row,false)
					end
					if function==3
						@func.findStrInRows(row,str)
					end
				end
			end
			count+=1
        }
		puts "\t"+count.to_s+" rows have been loaded successfully!"
		if function==1 or function==0
			atts.each{|a| f[a].close if f[a]!=nil; Utilities.countInstances(@defines.dirs['dataDir']+a); }
		end
		if function==2 or function==0
			@func.analysis
		end
		@func.database.close
	end

	def makeTimelines(msec,path)
		@func.window=msec.to_i #store in msec
		@func.cwd=path
		cwd=path
		puts "> Start creating user timelines using window: "+msec+" msec"
		path=cwd+@defines.userDir
		entries=Dir.entries(path) rescue entries=Array.new
		if entries.size > 3 # DIRECTORY EXISTS AND IS NOT EMPTY
			puts "> Found existing per user files..."
			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
			@func.readUserAcrivity(entries)
		else
			if not File.exists?(cwd)
				puts "Dir not found"
			else
				Utilities.error("THIS FUNCTION NEEDS REVISION")
	#			Dir.mkdir path unless File.exists?(path)
	#			Dir.mkdir path+@defines.tmln_path unless File.exists?(path+@defines.tmln_path)
	#			puts "> There is not any existing user files. Separating timeline events per user..."
				# Post Timeline Events Separation (per user)
	#			if not File.exists? cwd+@defines.dataDir
	#				puts "Error: No file exists please run again with -s option"
	#			else
	#				@func.createTimelines()
	#			end
			end
		end
	end

	def plot(path)
		@defines.dirs['rootDir']=path
		@defines.dirs['plotDir']=@defines.dirs['rootDir']+@defines.plotDir
		if not File.exists? @defines.dirs['rootDir']
			Utilities.error "Directory does not exists."
			return
		end
		Dir.mkdir @defines.dirs['plotDir'] unless File.exists?(@defines.dirs['plotDir'])
		if @database==nil
			@database=Database.new(@defines,nil,nil)
		end
		plotter=Plotter.new(@defines,@database)
		puts "> Plotting existing output from <"+path+">..."

		#FILE-BASED
	#	plotter.plotFile()		

		#DB-BASED
		whatToPlot={"priceTagPopularity" => ["priceTable","priceTag"],
					"priceTagsPerDSP" => ["priceTable","host"],
					"beaconTypesCDF" => ["bcnTable","beaconType"],
					"categoriesTrace" => ["traceTable","advertising,analytics,social,beacons,content,other,adRelatedBeacons"],
					"percSizeCategoryPerUser" => ["userTable","totalSizePerCategory"],
					"categoriesPerUser" => ["userTable","advertising,analytics,social,content,noAdBeacons,other"],	
					"sizesPerReqsOfUsers"=> ["userTable","advertising,analytics,social,content,noAdBeacons,other,totalSizePerCategory"] #stacked area
							#boxplot price values (normalized xaxis window/avg reqs
							#boxplot number of detected prices
					}
		whatToPlot.each{|name, specs|	plotter.plotDB(name,specs)}
	end
end
