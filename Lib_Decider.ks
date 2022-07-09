function Decider{
	Local Ret is False.
	until Ret<>False or dQueue:empty{
		Set ret to fs:delegate[dQueue:pop()]:call.
	}
	Return Ret.
}
	
Function Execute{      	//execute task list in sequence
	Local Ret to True.
	statusupdate().
	until FS:TaskList:empty or Ret <> True{
		Local Qsave to false.
		if fs:tasklist<>"DummyTask"{
			SLog("Executing "+ FS:TaskList[0]).
		}
		set Ret to FS:Delegate[FS:TaskList[0]]:call.
		
	slog("Ran it").	
		if Ret=True{
			If FS:TaskList[0]="Circularise"{
				Set Qsave to true.  //set this before removing from list.
			}	
			FS:TaskList:remove(0).
	slog("Removed").		
			wait 0.1.
			if Qsave{
				kuniverse:quicksave().
				SLog("QuickSaved").
			}
		}
		WriteJSON(FS,"1:/Status.json").	
		statusupdate().
	}
	wait 0.1.
	Return "Phase Complete".
}		
if fs:delegate:haskey("Execute")=false {fs:delegate:add("Execute",Execute@).}




//*************Launch*************

Function d_Launch{
	if (ship:status="PRELAUNCH" or ship:status="Landed"){
		SLOG("Runing D_Launch").
		loadfile("Lib_Launch",False).
		dQueue:clear.
		dQueue:push("d_Launch_Equatorial").
		dQueue:push("d_Launch_Polar").
		dQueue:push("d_Launch_Intercept").
		dQueue:push("d_Launch_Child").
		dQueue:push("d_Launch_Sibling").
		Local Ret to Decider().
		dQueue:clear.
		Return Ret.		
	}else{
		Return False.
	}
}
if fs:delegate:haskey("d_Launch")=false {fs:delegate:add("d_Launch",d_Launch@).}

Function d_Launch_Equatorial{
	if ship:body=fs:targetbody and fs:Task="Equatorial"{	
		set FS:Angle to 90.
		SetLaunchAlt().
		AddTask("Launch").
		AddTask("Circularise").
		Return "Execute".
	}else{
		Return false.
	}
}
if fs:delegate:haskey("d_Launch_Equatorial")=false {fs:delegate:add("d_Launch_Equatorial",d_Launch_Equatorial@).}

Function d_Launch_Polar{
	if ship:body=fs:targetbody and fs:Task="Equatorial"{	
		set FS:Angle to -3.
		SetLaunchAlt().
		AddTask("Launch").
		AddTask("Circularise").
		Return "Execute".
	}else{
		Return false.
	}
}
if fs:delegate:haskey("d_Launch_Polar")=false {fs:delegate:add("d_Launch_Polar",d_Launch_Polar@).}









Function d_Transit{
	if ship:body<>fs:targetbody{
		slog("Need to Transit").
		//set up next list and run decider or add tasks and return Execute
		return false.
	}else{
		return false.
	}
}
if fs:delegate:haskey("d_Transit")=false {fs:delegate:add("d_Transit",d_Transit@).}




Function d_Land{
	if fs:task:startswith("Land")=true{
		slog("Need to Land").
		//set up next list and run decider or add tasks and return Execute
		return false.
	}else{
		return false.
	}
}
if fs:delegate:haskey("d_Land")=false {fs:delegate:add("d_Land",d_Land@).}




Function d_Rendezvous{
	if fs:task="Dock" or fs:task="Formate"{
		slog("Need to Rendezvous").
		//set up next list and run decider or add tasks and return Execute	
		return false.
	}else{
		return false.
	}
}
if fs:delegate:haskey("d_Rendezvous")=false {fs:delegate:add("d_Rendezvous",d_Rendezvous@).}
