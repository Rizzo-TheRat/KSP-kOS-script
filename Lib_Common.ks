function ApsAlt{  		//Altitude of specified apsis
	parameter Apsis.  // Pe, Ap, Near or Far.
	if Apsis = Pe{
		Return ship:periapsis.
	}else if Apsis = Ap{
		Return Ship:apoapsis.
	}else if Apsis = Far{
		Set halfOrb to ship:orbit:period/2.
		if abs(HalfOrb-eta:periapsis)<abs(HalfOrb-eta:apoapsis){
			Return ship:periapsis.
		}else{
			Return ship:apoapsis.
		}
	}else if Apsis = Near{
		if ship:status="Sub_Orbital"{
			return ship:apoapsis.
		}else if ship:status="Escaping"{
			return ship:periapsis.
		}else{
			Set halfOrb to ship:orbit:period/2.
			if abs(HalfOrb-eta:periapsis)>abs(HalfOrb-eta:apoapsis){
				Return ship:periapsis.
			}else{
				Return ship:apoapsis.
			}
		}	
	}else if Apsis = Nxt{
		if ship:status="Sub_Orbital"{
			return ship:apoapsis.
		}else if ship:status="Escaping"{
			return ship:periapsis.
		}else{
			if eta:periapsis<eta:apoapsis{
				Return ship:periapsis.
			}else{
				Return Ship:apoapsis.
			}
		}	
	}else{
		Slog("Error in ApsAlt - " + Apsis).
		Return 0.
	}
}

function ApsEta{			//ETA of speficied Apsis
	parameter Apsis.  // Pe, Ap, Near, Far, Nxt or Bod.
	if Apsis = Pe{
		Return eta:periapsis.
	}else if Apsis = Ap{
		Return eta:apoapsis.
	}else if Apsis = Far{
		Set halfOrb to ship:orbit:period/2.
		if abs(HalfOrb-eta:periapsis)<abs(HalfOrb-eta:apoapsis){
			Return eta:periapsis.
		}else{
			Return eta:apoapsis.
		}
	}else if Apsis = Near{
		if ship:status="Sub_Orbital"{
			return eta:apoapsis.
		}else if ship:status="Escaping"{
			return eta:periapsis.
		}else{
			Set halfOrb to ship:orbit:period/2.
			if abs(HalfOrb-eta:periapsis)>abs(HalfOrb-eta:apoapsis){
				Return eta:periapsis.
			}else{
				Return eta:apoapsis.
			}
		}
	}else if Apsis = Nxt{
		if ship:status="Sub_Orbital"{
			return eta:apoapsis.
		}else if ship:status="Escaping"{
			return eta:periapsis.
		}else{
			return min(eta:periapsis,eta:apoapsis).
		}
	}else if Apsis=Bod{
		return (eta:transition + orbit:nextpatch:nextpatcheta)/2.
	}else{
		Slog("Error in ApsEta").
	}
}

function BurnCalc{		//Returns time to burn specified dV
	parameter dVreq.
	set dVreq to abs(dVreq).
	local StageThrust is list().
	local StageISP is list().
	local StageMass is list().
	local StageDryMass is list().
	
	//Count stages
	list Engines in EngList.
	local numstages to -1.
	for engine in englist{
		if engine:decoupledin>numstages{
			set numstages to engine:decoupledin.
		}
	}
	if numstages>1{
		//setup arrays	set i to 0.	
		local i to 0.
		until i>numstages{
			Stagemass:add(0).
			StageDryMass:add(0).
			StageISP:add(0).
			StageThrust:add(0).
			set i to i+1.
		}

		//Thrust.
		for Eng in Englist{
			if eng:decoupledin>-1{
				set stagethrust[eng:decoupledin] to stagethrust[eng:decoupledin]+eng:possiblethrustat(0).
			}
		}

		//ISP
		for Eng in Englist{
			if eng:decoupledin>-1{
				set StageISP[eng:decoupledin] to stageISP[eng:decoupledin] + eng:possiblethrustat(0)/StageThrust[eng:decoupledin]*eng:vacuumISP.
			}
		}

		//Mass
		list parts in partlist.
		for p in partlist{
			if p:decoupledin>-1{
				set stagemass[p:decoupledin] to stagemass[p:decoupledin]+p:mass.
				set stagedrymass[p:decoupledin] to stagedrymass[p:decoupledin]+p:drymass.
			}
		}

		local stagedV to 9.81*stageISP[numstages]*ln(ship:mass/(ship:mass-stagemass[numstages]+stagedrymass[numstages])).
		//local nextstagemass to ship:mass-stagemass[numstages].
		//local nextstage to min(0,numstages-1).
		//local nextstagedV to 9.81*stageISP[nextstage]*ln(nextstagemass/(nextstagemass-stagemass[nextstage]+stagedrymass[nextstage])).

		local FirstDuration to 0.
		local SecondDuration to 0.
		
		if dVreq<stagedV or numstages=0 {
			set FirstDuration to ship:mass * stageISP[numstages] * 9.81 / stagethrust[numstages] * (1-constant:e^ (-abs(dVreq)/(stageISP[numstages]*9.81))).
		}else{
			set FirstDuration to ship:mass * stageISP[numstages] * 9.81 / stagethrust[numstages] * (1-constant:e^ (-abs(stagedV)/(stageISP[numstages]*9.81))).
			set SecondDuration to (ship:mass-stagemass[numstages]) * stageISP[min(0,numstages-1)] * 9.81 / stagethrust[min(0,numstages-1)] * (1-constant:e^ (-(dVreq-stagedV)/(stageISP[min(0,numstages-1)]*9.81))).		
		}		
		return FirstDuration+SecondDuration.
	}else{
		Local TotISP to 0.
		for eng in englist{
			set TotISP to TotISP+ship:maxthrust/eng:possiblethrustat(0)*eng:vacuumISP.
		}
		local totdV to 9.81*TotISP*ln(ship:mass/ship:drymass).
		return ship:mass * TotISP * 9.81 / ship:maxthrust * (1-constant:e^ (-abs(dVreq)/(TotISP*9.81))).
	}
}

Function Circularise{	//circularise at the next Apsis
	Initialise().
	GimbalLimit(1).
	Local TargetAlt to 0.
	Lock CircBearing to VecBearing(ship:velocity:orbit).	
	if ship:body=fs:targetbody and fs:task="Equatorial Orbit"{	
		unlock CircBearing.
		set CircBearing to 90.
		Slog("Equatorial Orbit required").
	}
	Local ApsisVel to velocityat(ship,ApsEta(Nxt)+time:seconds):orbit.
	Local ReqSpd to sqrt(body:mu/(body:radius+ApsAlt(Nxt))).	
	local HorizVec to heading(CircBearing,0):vector.
	Local dSpd to ReqSpd-ApsisVel:mag.  //use dSpd to get the sign for the first half
	Local DirMod to sign(dSpd).
	local dVel to dSpd*ApsisVel:normalized.  //use dVel to get the directon for the second part.
	local HalfBurnDuration to BurnCalc(dSpd/2).

//	slog ("HalfBurn ",round(HalfBurnDuration,1)).
//	slog ("NodeSpeed ", round(ApsisVel:mag)).
//	slog ("ReqSpeed ",Round(ReqSpd)).
//	slog ("dVel ",round(dVel:mag,1)).


	
	if dVel:mag>0.5{
		SLog("Circularising at " + round(ApsAlt(Nxt)) + "m and " + round(CircBearing,2) + "deg.").				
		steerto(dVel).	
		if ApsEta(Nxt)-halfburnDuration>60 and ship:altitude>ship:body:atm:height{
			wait 0.1.
			Rails(ApsEta(Nxt)-HalfBurnDuration-60).
		}	
		Wait 0.	
		Physics(3).
		when Thrott>0 then{
			Physics(0).
		}
		Local StartTime to time:seconds+ApsEta(Nxt)-HalfBurnDuration*1.5.	
		local circmode to 0. 
		local elevation to 0. 		
		until dVel:mag<0.2{
			if ship:status="Escaping" and eta:periapsis>0{
				set circmode to 10.
			}else if eta:periapsis<1{
				set circmode to 20.
			}else if eta:apoapsis<eta:periapsis{
				set circmode to 22.
			}else if (ship:apoapsis-ship:periapsis)/ship:apoapsis>0.2{
				set circmode to 11.
			}else{
				set circmode to 21.
			}
			
			
//			if (ship:status="Escaping" or (ship:apoapsis-ship:periapsis)/ship:apoapsis>0.2) and eta:periapsis>0{ //ApsETA(Nxt)<ship:orbit:period/2{  //Apsis is ahead)       
			if circmode=10 or circmode=11 or circmode =12{
				set ApsisVel to velocityat(ship,apsETA(Nxt)+time:seconds):orbit.
				Set ReqSpd to sqrt(body:mu/(body:radius+ApsAlt(Nxt))).		
				Set Elevation to 90-abs(vang(ship:up:vector,ApsisVel)).
			//	Set ShipHeading to DirMod*heading(CircBearing,Elevation):vector.
				Set ShipHeading to DirMod*heading(VecBearing(ship:velocity:orbit),Elevation):vector.				
				Set dSpd to abs(ReqSpd-ship:velocity:orbit:mag).
				set dVel to dSpd*-ship:velocity:orbit:normalized.
				sDisp("CircMode ", circmode).
			}else{
				set ReqVel to sqrt(body:mu/(body:radius+ship:altitude))*vxcl(ship:up:vector,ship:velocity:orbit):normalized.
				//local HorizVec to heading(CircBearing,0):vector.				
				Set dVel to ReqVel-velocity:orbit.
				set shipheading to dVel.
				set dSpd to dVel:mag.	
				set elevation to 0.
				sDisp("CircMode ", circmode).				
			}
			ThrottSet(1,StartTime,dSpd,2).
			//sDisp("Start Burn ",round(StartTime-time:seconds)).
			SDisp("TWR",round(ship:availablethrust/(ship:mass*body:mu/(ship:altitude+body:radius)^2),2)).
			SDisp("dVel",round(dVel:mag,2)).
			SDisp("Heading", VecBearing(ship:velocity:orbit)).
			sDisp("Elevation",Elevation).
			SUpdate().
		}	
	}
	Set Thrott to 0.
	wait 0.
	//removefilelist("Lib_Launch").
	Return True.
}		
if fs:delegate:haskey("Circularise")=false {fs:delegate:add("Circularise",Circularise@).}

Function GimbalLimit{  //limits gimbal on all engines
	Parameter lim.
	list Engines in EngList.
	for eng in Englist{
	if eng:hasmodule("ModuleGimbal"){
			eng:getmodule("ModuleGimbal"):setfield("Gimbal Limit",lim).
		}
	}
}

Function Initialise{		//Setup essential parameters
	if ship:mass >50{ 
		set steeringmanager:maxstoppingtime to 5.
		set steeringmanager:pitchts to 5.
		set steeringmanager:yawts to 5.
	}else{
		set steeringmanager:maxstoppingtime to 2.
		set steeringmanager:pitchts to 5.
		set steeringmanager:yawts to 5.
	}
	set config:ipu to 400.
	SAS off.
	RCS off.
	Global ShipHeading to ship:facing:forevector.
	Lock steering to ShipHeading.
	Global Thrott to 0.
	Lock throttle to Thrott.
	GimbalLimit(20).
	brakes off.
	Lights off.
	set ship:control:translation to v(0,0,0).	
	supdate().
	CLEARVECDRAWS().
	staging().
	wait 0.	
}

function Limit{   		//limit a value to a minimum and maximum
	Parameter MinVal,Inval,MaxVal.
	return max(minval,min(MaxVal,Inval)).
}	

Function Physics{		//Physics warp speed
	parameter PhysMode is 0.
	core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
	Set kuniverse:timewarp:mode to "PHYSICS".
	wait until kuniverse:timewarp:mode = "PHYSICS".
	if PhysMode>0{
		Set Warp to PhysMode.
	}else{
		Set Warp to 0.
	}
}

Function SetDropTank{
	local TankStage to 0.
	local EngStage to 0.
	list Engines in EngList.
	for eng in englist{
		if eng:decoupledin>engstage{
			set engstage to eng:decoupledin.
		}
	}
	list parts in partlist.
	for p in partlist{
		local reslist to p:resources.
		for r in reslist{
			if r:name="LiquidFuel" and p:decoupledin>TankStage{
//				Set DropTank to p.
				set DropFuel to r.
				set TankStage to p:decoupledin.
			}
		}
	}
	if tankstage>EngStage and stage:number>0{
		slog("Droptank enabled").
		when dropfuel:amount<0.01 then{
			if ship:body=fs:targetbody and ship:status="Sub_orbital" and ship:verticalspeed<0 {
				slog("Drop tanks empty but not dropped").
			}else{
				stage.
				SetDropTank().
			}
		}
	}
}

function staging{		//Setup staging
	//Staging
	Global InitThrust to ship:availablethrust.
	Local EngList is List().
	when ship:availableThrust < InitThrust then {
		Local StageNow to False.
		Local Spent is false.  //do we have spent engines
		Local Fresh is false.  //do we have fresh engines		
		list engines in Englist.
		if EngList:Length>0 {
			for Eng in Englist{
				if Eng:flameout {
					Set spent to True.
				}else{
					set fresh to true.
				}
			}
		}
		if ship:status="PreLaunch" or (spent=true and fresh=true){
			set StageNow to True.
		}

		If StageNow=True and stage:number>0{
			sLog("staging").
			local Warpval to 0.
			if warp>0{
				set Warpval to Warp.
				set warp to 0.
				wait 0.4.
			}
			wait 0.1.
			Stage.
			setdroptank().
			wait 0.1.
			set warp to WarpVal.
		}
		Set InitThrust to Ship:availableThrust.
		Return True.
	}
	wait 0.
}

Function ThrottSet{		//Set throttle
	Parameter Accuracy, StartTime, AccSet, AccMin.
	Local ThrottSetting to ship:Mass * abs(AccSet) / max(0.1,Ship:AvailableThrust).
	Local MaxAcc to ship:availablethrust/ship:mass.
	set ThrottMin to min(1,ship:Mass * abs(AccMin) / max(0.1,Ship:AvailableThrust)).

	if starttime>time:seconds+2{
		SDisp("Burn in ",  round(starttime-time:seconds)).
	}	
	SDisp("Steering Error",round(abs(SteeringManager:AngleError),2)).	
	if abs(SteeringManager:ANGLEERROR)<Accuracy and time:seconds>StartTime{ 
	//if vang(ship:facing:forevector,steering:vector)<Accuracy and time:second>StartTime{
		Set Thrott to limit(ThrottMin,ThrottSetting,1).//max(ThrottMin,ThrottSetting).
	}else{
		Set Thrott to 0.
	}
	SDisp("Throttle",round(Thrott,4)).
	SDisp("Acc Set", round(abs(Thrott*MaxAcc),2)).
	//Return Thrott.
}

Function VecBearing {	//Bearing of input vector
	Parameter InVector.
	Local HVec to vxcl(ship:up:vector,InVector).  //Horizontal velocity vector
	Local NAngle to vang (ship:north:vector,HVec).  //Horizontal angle from North
	Local EastVec to -vcrs(ship:north:vector,Ship:up:vector).  //Vector pointing East 
	Local EAngle to vang(EastVec,HVec).
	if EAngle>90 {
		Set CurrentBearing to -NAngle.
	} else {
		Set CurrentBearing to NAngle.
	}
	Return CurrentBearing.
}