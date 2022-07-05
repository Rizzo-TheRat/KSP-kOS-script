// setup screen
Global Midscreen to 8.
Global Lowscreen to Midscreen+12.
Global fullscreen to 50.
Set TERMINAL:WIDTH TO 50.
Set TERMINAL:HEIGHT TO fullscreen.


Global DispList is list().  //SLog output data
Global BlankLine to " ".
Global MissionComplete to False.



Global Thrott to 0.




//Persistant data for the json file
Global FS is Lexicon().
FS:add("TargetBody",ship:body).  //set target if not blank
FS:add("Task","").		  		//current tasking
FS:add("TargetShip","").  		//set target if not blank
FS:add("Status","").	  		//current ship status - not sure if needed now
FS:add("TaskList",List()).		//Mission stack list of tasks
FS:add("FileList",List()).		//list of files to open at startup
FS:add("Delegate",Lexicon()).	//List of delegate functions.
FS:add("Alt",0).          		//Intermediate alttiude setting
FS:add("FinalAlt",0).     		//target altitude for bodies
FS:add("Time",0).         		//Always a world time of an event
FS:add("dTime",0).  	  		//Always a delta time to an event
FS:add("Angle",0).		  		//Needed for some calculations depending on status
FS:add("Lat",0).				//Lat and Lng for landing point.
FS:add("Lng",0).

//Run the cursor down the screen
Local outline to 0.
until outline=Lowscreen-1{
	print " ".
	set outline to outline+1.
}

//set blank text line
until blankline:length = terminal:width-1{
	set blankline to blankline + " ".
}


StatusUpdate().
Supdate().

Loadfile("Lib_Decider",false).
Loadfile("Run_Mission",false).















Slog(" ").
Slog("Done").
wait 2.
reboot.


//FUNCTIONS

//Screen logging
function SLog{  //adds a new line to bottom section of screen
	parameter intext, moretext is "".
	if moretext:typename="Scalar"{
		set intext to intext+" "+round(moretext,2):tostring.
	}else{ 
		set intext to intext+" "+moretext:tostring.	
	}
	//indent to make seeing new tasks easier
	if intext:startswith("Processing")=False{
		set intext to " " + Intext.
	}
	print intext.
	StatusUpdate().  //reprint the top layer stuff every time a new line is added to the log
}

//print status to top of screen and set up seperator lines
Function StatusUpdate{ 	
	print (" Target Body:  " + FS:TargetBody:name):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at (0,0).
	print ("Ship mission:  " + FS:Task):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at (0,1).
	print (" Target Ship:  " + FS:TargetShip):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at (0,2).
	print ("Mission Stat:  " + FS:Status):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at (0,3).
	Print ("Current Body:  " + ship:body:name):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at (0,4).
	print (" Ship status:  " + Ship:status):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at(0,5).
	print (" "):padright(terminal:width-10):substring(0,terminal:width-15)+"|" at(0,6).
	Local seperator to "_".
	until seperator:length = terminal:width-1{
		set seperator to seperator + "_".
	}
	Global blankline to " ".
	until blankline:length = terminal:width-1{
		set blankline to blankline + " ".
	}	
	print seperator at (0,Lowscreen-1).
	print seperator at (0,Midscreen-1).
	
	local tasknum to 0.
	until tasknum=midscreen-1{
		local outtext to "".
		if tasknum<	fs:tasklist:length{
			set outtext to fs:tasklist[tasknum]:padright(15):substring(0,13).
		}else{
			set outtext to (" "):padright(15):substring(0,13).
		}
		print outtext at (terminal:width-14,tasknum).
		set tasknum to tasknum+1.
	}
}		

//Display variable to be continuously updated within a loop
Function SDisp{ 	
	parameter disptitle,dispvalue is "".
	set disptitle to disptitle:tostring:padright(terminal:width-15).
	if dispvalue:typename="Scalar"{	
		DispList:add(Disptitle + round(DispValue,2)).
	}else{
		DispList:add(Disptitle + DispValue).	
	}
}

//Print out the logged parameters
function SUpdate{
	//make sure not too long
	until DispList:length<Lowscreen-Midscreen{
		DispList:remove(0).
	}
	//Print them out
	Local dispitem to 0.
	until dispitem=DispList:length{
		print DispList[dispitem]:tostring:padright(terminal:width-1) at (0,Midscreen+dispitem).
		set dispitem to dispitem+1.
	}
	until dispitem=lowscreen-midscreen-1{
		print blankline at (0,midscreen+dispitem).
		Set dispitem to dispitem+1.
	}
	//Clear the data
	DispList:clear().
	wait 0.
}



Function Menudraw{  	//Generates the menu and returns the selection text
	parameter Inlist,MenuText.  //inlist is up to 10(?) items to be selected.  Menutext is question.
	if inlist:length=0{
		return "".
	}else{
		Local ItemNum to 0.
		SUpdate().
		SDisp( "Select " + MenuText,"").
		until ItemNum=Inlist:length{
			SDisp( ItemNum + " - " + Inlist[ItemNum],"").
			Set ItemNum to ItemNum+1.
		}
		SUpdate().
		Local MenuVal to -1.
		Until Menuval>-1 and Menuval<inlist:length{
			set MenuVal to Terminal:Input:getchar().
			if Menuval="."{
				Reboot.
			}
		}
		return inlist[Menuval:tonumber].
	}
}

//Load and run a file
Global Function Loadfile{
	Parameter Filename,CompileIt is false. //true to compile
	if ship:connection:isconnected{
		Loadfile2(Filename,CompileIt).
	}else if exists("1:/" + Filename + ".ks") or exists("1:/" + Filename + ".ksm"){
		Slog("No connection, using existing copy of "+ Filename).
	}else{
		slog("Waiting for connection...").
		wait until not(addons:rt:available and ship:connection:isconnected) or (addons:rt:available and addons:rt:haskscconnection(ship)).
		set warp to 0.
		wait until kuniverse:timewarp:issettled.	
		slog("Connection established").	
		Loadfile2(Filename,CompileIt).
	}
	RUNPATH("1:/" +filename).
}

//Copy scripts to local volume and run them.
Function LoadFile2{
	parameter Filename, CompileIt.
	if CompileIt{
		Switch to 0.
		compile Filename.
		switch to 1.
		COPYPATH("0:/" +FileName +".ksm", "").
		sLog( "Compiled " + Filename).  
	}else{
		COPYPATH("0:/" +FileName +".ks", "").
		SLog( "Loaded " + Filename).		
	}
}