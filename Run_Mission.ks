//set up the mission

@LazyGlobal off.
//Top Level Menu
Local MenuList to list("Single Task","New Mission").
Local TgtList to list().


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
	
	}else if shipmission=Orbit{
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



local dList is List().

dList:add("d_Launch").
dList:add("d_Transit").
dList:add("d_Land").
dList:add("d_Rendezvous").


local ret is Slog(Decider(dList)).
slog("******************").
slog(ret).












