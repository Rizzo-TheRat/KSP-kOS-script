//set up the mission

@LazyGlobal off.
//Top Level Menu
Local MenuList to list("Single Task","New Mission").
Local TgtList to list().

if fs:delegate:haskey("m_Launch")=false {fs:delegate:add("m_launch",m_Launch@).}



if exists("1:/Status.json") {
	Local Shipfile to ReadJSON("1:/Status.json").
	print ShipFile:TargetBody at (15,0).
	print ShipFile:Task at (15,1).
	print ShipFile:TargetShip at (15,2).
	print ShipFile:Status at (15,3).
	MenuList:add("Existing File").
}
Local ShipMission to MenuDraw(Menulist,"Select Mission").


if shipmission="New Mission"{
	//select body
	local bd to kerbin.
	local Tgt to Sun.
	until Tgt=bd or tgt:orbitingchildren:length=0 {
		set bd to Tgt.
		set TgtList to bd:orbitingchildren.
		Menulist:clear.		
		TgtList:insert(0,bd).
		local i to 0.
		until i=tgtlist:length{
			MenuList:insert(i,TgtList[i]:name).

			set i to i+1.
		}
		set tgt to Body(MenuDraw (MenuList,"Select Body")).
	}
	set fs:targetbody to tgt.
	slog("Target body",fs:targetbody:name).

	//select task, level 1
	menulist:clear.
	if fs:targetbody:hassolidsurface{
		menulist:add("Land").
	}
	menulist:add("Orbit").
	menulist:add("Rendezvous").
	Local ShipMission to MenuDraw(Menulist,"Select Task").

	//level 2
	menulist:clear.
	if shipmission="Land"{
		menulist:add("Land at co-ordinates").
		menulist:add("Land on target").
		menulist:add("Land near target").
		if fs:targetbody:name="Kerbin"{	
			menulist:add("Land at KSC").		
		}
	
	}else if shipmission="Orbit"{
		menulist:add("Equatorial").
		menulist:add("Polar").
		menulist:add("Match Plane").
	
	}else if shipmission="Rendezvous"{
		menulist:add("Dock").
		menulist:add("Formate").		
	}
	Local ShipMission to MenuDraw(Menulist,"Select Task").	
	
	set FS:Task to ShipMission.
	slog("Mission",Shipmission).

	//select target
	menulist:clear.
	local targetlist to list().
	List targets in targetlist.
	if ShipMission="Land on target" or ShipMission="Land near target"{
		for tgt in targetlist{
			if tgt:body=fs:targetbody and Tgt:Status ="Landed" and tgt:type<>"Debris"{
				menulist:add(tgt:name).
			}
		}
	}else if ShipMission="Dock" or ShipMission="Formate"{
		for tgt in targetlist{
			if tgt:body=fs:targetbody and (Tgt:Type ="Ship" or Tgt:Type="Station" or Tgt:Type="Probe"){
				menulist:add(tgt:name).
			}
		}
	}else if ShipMission = "Match Plane"{
		menulist:clear.
		menulist:add("Satellite/Moon").
		menulist:add("Planet").		
		
	}
	Local ShipMission to MenuDraw(Menulist,"Select target").	
} 


Loadfile("Lib_Common",false).

//Global sList is queue().
//need to sequence this not decide it - run all of them regardlessl of output
//sList:clear.
//sList:push("d_Launch").
//sList:push("d_Transit").
//sList:push("d_Land").
//sList:push("d_Rendezvous").
//until MissionComplete=true{
//	local NextFunc is Decider(dQueue).
//	Slog("Next Function: ",NextFunc).
//	FS:Delegate[NextFunc]:call. 
//}

Until MissionComplete=True{
	m_Mission().

//	m_Launch().
//	m_Transit().
//	m_Land().
//	m_Rendezvous().
}

slog("******************").
slog("Mission Complete").



//    ***************
//    *  FUNCTIONS  *
//    ***************


Function m_Mission{
	SLOG("Runing Main Mission").
	dQueue:clear.
	dQueue:push("m_Launch").
	dQueue:push("m_Transit").
	dQueue:push("m_Land").
	dQueue:push("m_RendezVous").
	Local Ret to Decider().
	if Ret=False{
		Return Ret.
	}else{
		FS:delegate[Ret]:call.
	}
	dQueue:clear.
}




Function m_Launch{
	if (ship:status="PRELAUNCH" or ship:status="Landed"){
		loadfile("Lib_Launch",False).
		return "d_Launch".
	}else{
		return False.
	}
}


Function m_Transit{
	if ship:body<>fs:targetbody{
		slog("Need to Transit").
		d_Transit().		
	}
}
//if fs:delegate:haskey("d_Transit")=false {fs:delegate:add("d_Transit",d_Transit@).}

Function m_Land{
	if fs:task:startswith("Land")=true{
		slog("Need to Land").
		dLand().	
	}
}
//if fs:delegate:haskey("d_Land")=false {fs:delegate:add("d_Land",d_Land@).}

Function m_Rendezvous{
	if fs:task="Dock" or fs:task="Formate"{
		slog("Need to Rendezvous").
		dRendezvous().		
	}
}
//if fs:delegate:haskey("d_Rendezvous")=false {fs:delegate:add("d_Rendezvous",d_Rendezvous@).}









