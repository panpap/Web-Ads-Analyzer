load 'define.rb'
load 'core.rb'
load 'plotter.rb'
require 'digest/sha1'

class Operations
	@@loadedRows=nil
	
	def initialize(filename,dump)
		@dump=dump
		@defines=Defines.new(filename)
		@func=Core.new(@defines,dump)
	end

	def loadFile()
		puts "> Loading Trace..."
		@@loadedRows=@func.loadRows(@defines.traceFile)
		puts "\t"+@@loadedRows.size.to_s+" requests have been loaded successfully!"
	end

    def separate
		atts=@@loadedRows[0].keys
		f=Hash.new
		atts.each{|a| f[a]=File.new(@defines.dirs['dataDir']+a,'w')}
        for row in @@loadedRows do
            atts.each{|att| f[att].puts row[att] if att!='url'}
			Utilities.separateTimelineEvents(row,@defines.dirs['userDir']+row['IPport'],@defines.column_Format)
   		end
		atts.each{|a| Utilities.countInstances(@defines.dirs['dataDir']+a); f[a].close}
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
				puts "NEEDS REVISION"
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

  	def analysis      
		puts "> Stripping parameters, detecting and classifying Third-Party content..."
		for r in @@loadedRows do
			@func.parseRequest(r,false)
		end
		analysisResults(@func.trace)
	end

	def findStrInRows(str,printable)
		count=0
		found=Array.new
		puts "Locating String..."
		rows=@func.getRows
		for r in rows do
			for val in r.values do
				if val.include? str
					count+=1
					if(printable)
						url=r['url'].split('?')
						Utilities.printRow(r,STDOUT)
					end
					found.push(r)					
					break
				end
			end
		end 
		if(printable)
			puts count.to_s+" Results were found!"
		end
		return found
	end

	def plot(path)
		@defines.dirs['rootDir']=path
		@defines.dirs['plotDir']=@defines.dirs['rootDir']+@defines.plotDir
		Dir.mkdir @defines.dirs['plotDir'] unless File.exists?(@defines.dirs['plotDir'])
		if @database==nil
			@database=Database.new(@defines.dirs['rootDir']+@defines.resultsDB,@defines)
		end
		plotter=Plotter.new(@defines,@database)
		puts "> Plotting existing output from <"+path+">..."
		
		#DB-BASED
		whatToPlot={"priceTag" => @defines.tables['priceTable'],
					"host"=> @defines.tables['priceTable'],
#					"beaconType" => @defines.tables['bcnTable'],
				#	"thirdPartyContent" => @defines.tables['traceTable'],
				#	"advertising,adExtra,analytics,social,content,noAdBeacons,other" => @defines.tables['userTable'],
				#	"advertising,adExtra,analytics,social,content,noAdBeacons,other,thirdPartySize" => @defines.tables['userTable']
					}
		whatToPlot.each{|column, table|	plotter.plotDB(table,column)}

		#FILE-BASED
		plotter.plotFile()
		system("rm -f .*.data")
	end

#------------------------------------------------------------------------


	private

	def analysisResults(trace)
		fw=nil
		if @dump
			puts "> Dumping to files..."
			fd=File.new(@defines.files['devices'],'w')
			trace.devs.each{|dev| fd.puts dev}
			fd.close
			fpar=File.new(@defines.files['restParamsNum'],'w')
			trace.restNumOfParams.each{|p| fpar.puts p}
			fpar.close
			fpar=File.new(@defines.files['adParamsNum'],'w')
			trace.adNumOfParams.each{|p| fpar.puts p}
			fpar.close
			fsz=File.new(@defines.files['size3rdFile'],'w')
			trace.sizes.each{|sz| fsz.puts sz}
			fsz.close
		end
		puts "> Calculating Statistics about detected ads..."
		#LATENCY
	#	lat=@func.getLatency
	#	avgL=lat.inject{ |sum, el| sum + el }.to_f / lat.sizeclos
	#	Utilities.makeDistrib_LaPr(@@adsDir)
#		system("sort "+@defines.files['priceTagsFile']+" | uniq >"+@defines.files['priceTagsFile']+".csv")
#		system("rm -f "+@defines.files['priceTagsFile'])
		puts @func.trace.results_toString(@func.database,@defines.tables['traceTable'],@defines.tables['bcnTable'])
		@func.perUserAnalysis()
	end
end

