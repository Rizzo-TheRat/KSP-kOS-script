@LazyGlobal off.
if ship=Kuniverse:activevessel{  //only boot on active ship
	local starttime to time:seconds.
	

    //uses the highest kOS module and sets the others to reboot regularly for use later
	local kOSPos to 0.
	for p in ship:parts{
		if p:hasmodule("kOSProcessor") and p:position:mag>kOSPos{
			set kOSPos to p:position:mag.
		}
	}
	if round(core:part:position:mag,2)=round(kOSPos,2){
		core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
	}else{
		wait 5.
		reboot.
	}

	//wait up to 5 seconds for a connection
	print "Waiting for connection..." at (0,10).
	until ship:connection:isconnected or time:seconds>starttime+5{
		print time:seconds-starttime at (0,11).
	}
	if ship:connection:isconnected{
		ClearFiles().
		LoadSystem().
	}else if exists("1:/lib_system.ks") or exists("1:/lib_system.ksm"){
		print "No connection, using existing system file" at (0,10).
		wait 1.
	}else{
//		print "Waiting for connection" at (0,10).
		Set kuniverse:timewarp:mode to "RAILS".
		wait until kuniverse:timewarp:mode = "RAILS".
		wait 0.
		set warp to 4.
		wait until ship:connection:isconnected.
		set warp to 0.
		wait until kuniverse:timewarp:issettled.				
		ClearFiles().
		LoadSystem().			
	}
	
	Clearscreen.
	RUNPATH("1:/lib_system").
//	StatusUpdate().  //seperators and mission details	
//	Loadfile("Mission",true).
}

Function ClearFiles{
	//Clear old files.
	switch to 1.
	wait 0.1.
	local filelist to list().
	List Files in FileList.
	for filename in filelist{
		if filename<>"boot" and filename<>"Status.json"{
			deletepath(filename).
		}
	}	

}

Function LoadSystem{
	Switch to 0.
	//compile "lib_system.ks".
	Switch to 1.
	COPYPATH("0:/lib_system.ks","1:lib_system.ks").  //CHANGE BACK TO KSM WHEN WORKING
}