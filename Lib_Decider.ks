if fs:delegate:haskey("d_Launch")=false {fs:delegate:add("d_launch",d_Launch@).}
if fs:delegate:haskey("d_Transit")=false {fs:delegate:add("d_Transit",d_Transit@).}
if fs:delegate:haskey("d_Land")=false {fs:delegate:add("d_Land",d_Land@).}
if fs:delegate:haskey("d_Rendezvous")=false {fs:delegate:add("d_Rendezvous",d_Rendezvous@).}


function Decider{
	parameter inlist is list().

	local i is 0.
	local Ret is False.
	until i=inlist:length or Ret<>False{
		slog(i,inlist[i]).
		set Ret to fs:delegate[inlist[i]]:call.
		set i to i+1.
	}
	wait 2.
	return Ret.
}


Function d_Launch{
	if (ship:status<>"PRELAUNCH." and ship:status<>"Landed."){
		Return False.
	}else{
		slog("Need to launch").
		Return "Launch".
	}
}


Function d_Transit{
	if ship:body=fs:targetbody{
		return False.
	}else{
		slog("Need to Transit").
		Return "Transit".		
	}
}


Function d_Land{
	if fs:task:startswith("Land")=false{
		Return False.
	}else{
		slog("Need to Land").
		Return "Land"	.	
	}
}


Function d_Rendezvous{
	if fs:task<>"Dock" and fs:task<>"Formate"{
		Return False.
	}else{
		slog("Need to Rendezvous").
		Return "Rendezvous".		
	}
}