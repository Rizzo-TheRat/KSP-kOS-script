function Decider{
	parameter inlist is list().
	local i is 0.
	local Ret is False.
	until i=inlist:length or Ret<>False{
		slog(i,inlist[i]).
		set Ret to fs:delegate[inlist[i]]:call.
		set i to i+1.
	}
	return Ret.
}


Function Execute{
	//execute task list in sequence
	Local Ret to True.
	statusupdate().
	until FS:TaskList:length = 0 or Ret <> True{
		Local Qsave to false.
		if fs:tasklist<>"DummyTask"{
			SLog("Processing "+ FS:TaskList[0]).
		}
		Set Ret to False.
		set Ret to fS:Delegate[FS:TaskList[0]]:call.
		if Ret=True{
			If FS:TaskList[0]="Circularise"{
				Set Qsave to true.  //set this before removing from list.
				set PhaseComplete to True.
			}	
			FS:TaskList:remove(0).
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
	Return Ret.
}	
if fs:delegate:haskey("Execute")=false {fs:delegate:add("Execute",Execute@).}

Function d_Launch{
	if (ship:status<>"PRELAUNCH" and ship:status<>"Landed"){
		Return False.
	}else{
		slog("Need to launch").
		loadfile("Lib_Launch",False).
		Return "d2_Launch".
	}
}
if fs:delegate:haskey("d_Launch")=false {fs:delegate:add("d_launch",d_Launch@).}

Function d_Transit{
	if ship:body=fs:targetbody{
		return False.
	}else{
		slog("Need to Transit").
		Return "Transit".		
	}
}
if fs:delegate:haskey("d_Transit")=false {fs:delegate:add("d_Transit",d_Transit@).}

Function d_Land{
	if fs:task:startswith("Land")=false{
		Return False.
	}else{
		slog("Need to Land").
		Return "Land"	.	
	}
}
if fs:delegate:haskey("d_Land")=false {fs:delegate:add("d_Land",d_Land@).}

Function d_Rendezvous{
	if fs:task<>"Dock" and fs:task<>"Formate"{
		Return False.
	}else{
		slog("Need to Rendezvous").
		Return "Rendezvous".		
	}
}
if fs:delegate:haskey("d_Rendezvous")=false {fs:delegate:add("d_Rendezvous",d_Rendezvous@).}

Function d2_Launch{
	dList:clear.
	dList:add("dLaunch_Equatorial").
	dList:add("dLaunch_Polar").
	dList:add("dLaunch_Intercept").
	dList:add("dLaunch_Child").
	dList:add("dLaunch_Sibling").
	local NextFunc is Decider(dList).
	FS:Delegate[NextFunc]:call.
}
if fs:delegate:haskey("d2_Launch")=false {fs:delegate:add("d2_Launch",d2_Launch@).}

Function dLaunch_Equatorial{
	if ship:body=fs:targetbody and fs:Task="Equatorial"{	
		set FS:Angle to 90.
		SetInitialAlt().
		AddTask("Launch").
		AddTask("Circularise").
		Return "Execute".
	}else{
		Return false.
	}
}
if fs:delegate:haskey("dLaunch_Equatorial")=false {fs:delegate:add("dLaunch_Equatorial",dLaunch_Equatorial@).}

Function dLaunch_Polar{
	if ship:body=fs:targetbody and fs:Task="Equatorial"{	
		set FS:Angle to -3.
		SetInitialAlt().
		AddTask("Launch").
		AddTask("Circularise").
		Return "Execute".
	}else{
		Return false.
	}
}
if fs:delegate:haskey("dLaunch_Polar")=false {fs:delegate:add("dLaunch_Polar",dLaunch_Polar@).}
