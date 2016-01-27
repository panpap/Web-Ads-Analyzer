load 'user.rb'

class Trace
	attr_accessor :rows, :fromBrowser, :beacons,:totalAdBeacons, :party3rd,:restNumOfParams, :adNumOfParams, :devs, :numericPrices, :mobDev, :numOfMobileAds, :totalImps, :users, :hashedPrices, :sizes, :totalParamNum

	def initialize(defs)
		@defines=defs
		@rows=Array.new
		@mobDev=0
		@users=Hash.new
		#@totalParamNum=Array.new
		@hashedPrices=0
		@sizes=Array.new
		@devs=Array.new
		@fromBrowser=0
		@numericPrices=0
		@totalAdBeacons=0
		@numOfMobileAds=0
		@beacons=Array.new
		@adNumOfParams=Array.new
		@restNumOfParams=Array.new
		@totalImps=0
		@party3rd={"Advertising"=>0,"Social"=>0,"Analytics"=>0,"Content"=>0, "Other"=>0, "totalBeacons"=>0}
	end

	def analyzeTotalAds    #Analyze global variables
		Utilities.countInstances(@defines.files['adParamsNum'])
		Utilities.countInstances(@defines.files['restParamsNum'])
		Utilities.countInstances(@defines.files['devices'])
		Utilities.countInstances(@defines.files['size3rdFile'])
		#return Utilities.makeStats(@totalParamNum),Utilities.makeStats(@adNumOfParams),Utilities.makeStats(@restNumOfParams),Utilities.makeStats(@sizes)
		return Utilities.makeStats(@sizes)
	end

	def loadTrace(filename)
        f=File.new(filename,'r')
        line=f.gets     #get rid of headers
        while(line=f.gets)
			h=Format.columnsFormat(line,@defines.column_Format)
			if h['host'].size>1 and h['host'].count('.')>0
		        		rows.push(h)
			end
        end
        f.close
	end

	def results_toString(db,traceTable,beaconTable)
		totalNumofRows=@rows.size
		sizeStats=analyzeTotalAds
		#PRINTING RESULTS
		if traceTable!=nil
			s="> Printing Results...\n\n------------\nTRACE STATS\n"+"- Total users in trace: "+@users.size.to_s+
			"\n- Total Number of rows = "+(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+
			@party3rd['totalBeacons']+@party3rd['Content']+@party3rd['Other']-@totalAdBeacons).to_s+"\n- Traffic from  mobile devices: "+
			@mobDev.to_s+"/"+totalNumofRows.to_s+"\n"+"- Traffic originated from Web Browser: "+@fromBrowser.size.to_s+
			"\n- 3rd Party content detected: \n\tAdvertising => "+@party3rd['Advertising'].to_s+
			"\n\tAnalytics => "+@party3rd['Analytics'].to_s+"\n\tSocial => "+@party3rd['Social'].to_s+"\n\tContent => "+@party3rd['Content'].to_s+
			"\n\tBeacons => "+@party3rd['totalBeacons'].to_s+"\n\tOther => "+@party3rd['Other'].to_s+
			"\n- Size of the unnecessary 3rd Party content (i.e. Adverising+Analytics+Social)\n\tTotal: "+sizeStats['sum'].to_s+" Bytes - Average per req: "+
			sizeStats['avg'].to_s+" Bytes"+"\n\nADVERTISING CONTENT\n- AdRelated traffic from mobile devices: "+@numOfMobileAds.to_s+"/"+
			@party3rd['Advertising'].to_s+"\n- Prices Detected"+(@numericPrices+@hashedPrices).to_s+"\n\tHashed Price tags found: "+@hashedPrices.to_s+"\n- Numeric Price tags found: "+@numericPrices.to_s
			"\n- Prices tags from Browser sessions: "+
			"\n- AdRelated beacons: "+@totalAdBeacons.to_s+"/"+@party3rd['totalBeacons'].to_s+"\n------------\n"#-Impressions detected "+@totalImps.to_s+"\n"
	#        puts "Average latency "+avgL.to_s
			if db!=nil
				@beacons.each{|array| db.insert(beaconTable,array)}				
				totalRows=(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+@party3rd['totalBeacons']+@party3rd['Content']+@party3rd['Other']-@totalAdBeacons);
				id=Digest::SHA256.hexdigest (totalRows.to_s+"|"+@users.size.to_s)
				db.insert(traceTable,[id,totalRows,@users.size,@party3rd['Advertising'],@party3rd['Analytics'],@party3rd['Social'],
				@party3rd['Content'],@party3rd['totalBeacons'],@party3rd['Other'],
				sizeStats['sum'],@mobDev,@fromBrowser.size,@numOfMobileAds.to_s+"/"+
				@party3rd['Advertising'].to_s,@hashedPrices,@numericPrices,
				@totalAdBeacons.to_s+"/"+@party3rd['totalBeacons'].to_s,@totalImps])
			end
			return s
		else
			header="Total users in trace;Traffic from mobile devices;Traffic originated from Browser;Browser-prices;"+
			"3rd Party content detected: [Advertising,Analytics,Social,Content,Beacons,Other];"+
			"3rd Party content size: [Total,Average];Total Number of rows;Ad-related traffic using mobile devices;"+
			"hashed prices;numeric prices;Beacons found;Ads-related beacons;Impressions detected;noOfPublishers;Publishers;\n"
			s=@users.size.to_s+";"+
			@mobDev.to_+";"+@fromBrowser.to_s+";["+@party3rd['Advertising'].to_s+
			","+@party3rd['Analytics'].to_s+","+@party3rd['Social'].to_s+","+@party3rd['Content'].to_s+
			","+@party3rd['totalBeacons'].to_s+","+@party3rd['Other'].to_s+"];["+sizeStats['sum'].to_s+","+
			sizeStats['avg'].to_s+"];"+(@party3rd['Advertising']+@party3rd['Analytics']+@party3rd['Social']+
			@party3rd['totalBeacons']+@party3rd['Content']+@party3rd['Other']-@totalAdBeacons).to_s+";"+@numOfMobileAds.to_s+"/"+
			@party3rd['Advertising'].to_s+";"+@hashedPrices.to_s+";"+@numericPrices.to_s+
			";"+@party3rd['totalBeacons'].to_s+
			";"+@totalAdBeacons.to_s+"/"+@party3rd['totalBeacons'].to_s+";"+@totalImps.to_s+";"+@publishers.size.to_s+"\n"
			if @publishers.size>0 
				str="["
				@publishers.each{ |pubs| str=str+" | "+pubs}
				return header+s+str+"]\n"
			else
				return header+s+"\n"
			end
		end
	end
end

