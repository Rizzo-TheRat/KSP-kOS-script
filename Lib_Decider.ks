function Decider_old{
	parameter Q is queue().
	local Ret is False.
	until Q:empty or Ret<>False{
		slog("Decider: ",q:peek()).
		set Ret to fs:delegate[q:pop()]:call.
		slog("Return: ",Ret).
	}
	Q:clear.
	return Ret.
}

function Decider{
	Local Ret is False.
	until Ret<>False or dQueue:empty{
		set Ret to FS:Delegate[dQueue:pop()]:call.
	}
	Return Ret.
}
	


Function Execute_old{
	//execute task list in sequence
	Local Ret to True.
	statusupdate().
	until FS:TaskList:length = 0 or Ret <> True{
		Local Qsave to false.
		if fs:tasklist<>"DummyTask"{
			SLog("Processing "+ FS:TaskList[0]).
		}
		Set Ret to False.
		set Ret to FS:Delegate[FS:TaskList[0]]:call.
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
	Return "Phase Complete".
}
Function Execute{      	//execute task list in sequence
	Local Ret to True.
	statusupdate().
	until FS:TaskList:empty or Ret <> True{
		Local Qsave to false.
		if fs:tasklist<>"DummyTask"{
			SLog("Executing "+ FS:TaskList[0]).
		}
		
		slog("Executing Task: ",FS:Tasklist[0]).
		
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



Function d_Launch{
	SLOG("Runing D_Launch").
	dQueue:clear.
	dQueue:push("d_Launch_Equatorial").
	dQueue:push("d_Launch_Polar").
	dQueue:push("d_Launch_Intercept").
	dQueue:push("d_Launch_Child").
	dQueue:push("d_Launch_Sibling").
	Local Ret to Decider().
	if Ret=False{
		Return Ret.
	}else{
		FS:delegate[Ret]:call.
	}
	dQueue:clear.
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
