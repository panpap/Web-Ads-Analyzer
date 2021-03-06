require 'sqlite3'
load 'utilities.rb'

class Database

	def initialize(defs,dbName)		
		@defines=defs
		if dbName==nil and defs!=nil
			@db=SQLite3::Database.open @defines.dirs['rootDir']+@defines.resultsDB
		else
			@db=SQLite3::Database.open dbName
		end

		if defs!=nil
			@options=@defines.options
		end
		@db.execute 'PRAGMA main.page_size=4096;'
		@db.execute 'PRAGMA main.cache_size=10000;'
		@db.execute 'PRAGMA main.locking_mode=EXCLUSIVE;'
		@db.execute 'PRAGMA main.synchronous=NORMAL;'
		@db.execute 'PRAGMA main.journal_mode=WAL;'
		@db.execute 'PRAGMA main.temp_store = MEMORY;'
		@alerts=Hash.new(0)
		@farray=Hash.new
	end

	def insert(tbl, params)
		table=arrayCase(tbl)
		return -1 if blockOutput(table)
		par=prepareStr(params)
		if not @options["database?"]
			@farray[table]=File.new(@defines.dirs['rootDir']+table+".csv",'a') if @farray[table]==nil
			@farray[table].puts par
			return 1
		else
			return execute("INSERT INTO '#{table}' VALUES ",par)
		end
	end

	def insertBEACON(tbl, params)
		table=arrayCase(tbl)
		par=prepareStr(params)
		if not @options["database?"]
			@farray[table]=File.new(@defines.dirs['rootDir']+table+".csv",'a') if @farray[table]==nil
			@farray[table].puts par
			return 1
		else
			return execute("INSERT INTO '#{table}' VALUES ",par)
		end
	end

	def create(tbl,params)
		table=arrayCase(tbl)
		return if blockOutput(table)
		return execute("CREATE TABLE IF NOT EXISTS '#{table}' ",params) 
	end

	def count(tbl)
		table=arrayCase(tbl)
		return @db.get_first_value("select count(*) from "+table)
	end

	def get(tbl,what,param,value)
		table=arrayCase(tbl)
		if table==nil or param==nil or value==nil
			return
		end
		val=prepareStr(value)
		begin
			if what==nil
				return @db.get_first_row "SELECT * FROM '#{table}' WHERE "+param+"="+val	
			else
				return @db.get_first_row "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+val
			end
		rescue SQLite3::Exception => e 
			Utilities.error "SQLite Exception during GET! "+e.to_s+"\n"+table+" "+param+" "+value+"\n\n"+e.backtrace.join("\n").to_s
		end
	end

	def getAll(tbl,what,param,value,hash)
		@db.results_as_hash = true if hash
		table=arrayCase(tbl)
		if table==nil
			return
		end
		if param==nil
			if what==nil
				return @db.execute "SELECT * FROM '#{table}'"	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}'"
			end
		else
			val=prepareStr(value)
			if what==nil
				return @db.execute "SELECT * FROM '#{table}' WHERE "+param+"="+val	
			else
				return @db.execute "SELECT "+what+" FROM '#{table}' WHERE "+param+"="+val
			end
		end
	end

	def close
		if @alerts.size>0
			Utilities.warning "Your results may be biased..."
			puts "\tDublicates detected from Database: \n\t"+@alerts.to_s
		end
		#@farray.each{|file| file.close}
		@db.close if @db
	end
# -------------------------------------------

private

	def blockOutput(tbl)
		table=arrayCase(tbl)
		part=table.split("_")
		return true if @defines==nil
		return true if part.first==@defines.beaconDBTable and @defines.options["detectBeacons?"]==false
		return true if (part.last.include? "web" or part.last.include? "app") and @defines.options["webVsApp?"]==false
		blockOptions=@defines.options['tablesDB']
		return false if blockOptions[part.first]==nil
		return (not blockOptions[part.first])
	end

	def prepareStr(input)
		res=""
		if input.is_a? String 
			res='"'+input.gsub('"',"%22")+'"'
		else
			input.each{ |s| 
				if s.is_a? String
					str='"'+s.gsub("\n","").gsub('"',"%22")+'"'.force_encoding("iso-8859-1")
				else
					str=s.to_s.force_encoding("iso-8859-1")
				end
				if res!=""
					res=res+","+str.force_encoding("iso-8859-1")
				else
					res=str
				end}
		end
		return res
	end

	def execute(command,params)
		begin
			@db.execute command+"("+params+")"
			return 1
		rescue SQLite3::Exception => e 
			if e.to_s.include? "no such table" 
				Utilities.error "SQLite Exception: "+e.to_s+" "+command
			elsif e.to_s.include? "is not unique"
				table=command.split("INTO ")[1].split("VALUES")[0].gsub("'","")
				if @alerts[table]==nil or @alerts[table]==0
					Utilities.warning "not unique: "+table+"\n"+command+"("+params+")"
					@alerts[table]+=1
					return 0
				end
				@alerts[table]+=1
			elsif e.to_s.include? "UNIQUE constraint failed"
				table=e.to_s.split(": ")[1].split(".")[0]
				if @alerts[table]==nil or @alerts[table]==0
					Utilities.warning "UNIQUE constraint failed: "+table+"\n"+command+"("+params+")"
					@alerts[table]+=1
					return 0
				end
				@alerts[table]+=1
			else
				Utilities.error "SQLite Exception: "+command+" "+e.to_s+"\n"+params+"\n\n"+e.backtrace.join("\n").to_s
			end
			return -1
		end
	end
	
	def arrayCase(tbl)
		if tbl.kind_of?(Hash)	
			return tbl.keys[0] 
		else		#beaconsURL
			return tbl
		end
	end
end
