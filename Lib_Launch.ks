Function Launch{
	if ship:body:atm:exists{
		AtmoLaunch().
	}else{
		VacLaunch().
	}
}
if fs:delegate:haskey("Launch")=false {fs:delegate:add("Launch",Launch@).}


Function AtmoLaunch{
	Local Launchbearing to fs:angle.
	Local InitialAlt to ship:body:atm:height+10000.  //altitude of initial Ap
	Local APLead to 60.  //time to chase Apoapsis in seconds
	Local TWR to 0.      //initialise variable used to calculate turn angle
	Local TurnVel to 30. //Velocity to start turn
	Local ClimbAngle to 0. //Abgle from vertical
	Local CorrectedBearing to LaunchBearing.	//Don't correct to begin with
	Local initTopVec to ship:facing:topvector.

	if FS:FinalAlt<FS:InitialAlt{
		set FS:FinalAlt to FS:InitialAlt.
	}

	when ship:altitude>ship:body:atm:height*0.9 then{
		DeployFairing().
		Panels On.
	}

	Physics(0).
	Initialise().	//includes staging
//	SetAntenna().	//Set all to point at Kerbin  ONLY FOR REMOTETECH?

	set shipheading to lookdirup(heading(CorrectedBearing,90-Climbangle,0):vector,InitTopVec).
	Set Thrott to 1.
	
	//Launch
	if ship:maxthrust=0{
		set InitThrust to 1.  //trick staging in to operating
	}
	wait 0.1.
	Gear off.
	
	//Climb to initial turn
	until ship:velocity:surface:mag>TurnVel{
		set TWR to round(ship:availablethrust/(ship:mass*body:mu/(ship:altitude+body:radius)^2),2).
		SDisp("Altitude",round(ship:altitude)).
		SDisp("Speed", round(ship:velocity:surface:mag)).
		SDisp("TWR", round(TWR*Thrott,2) + " / " + TWR).
		SUpdate().
	}
	
	//Initial Turn	
	SLog("TWR at turn: "+ TWR).
	Local Turnpitch to max(1,20*TWR-30).	

	if fs:task="Sub Orbital"{
		set Turnpitch to 0.1.
	}
	
	SLog ("Turning to " + round(Turnpitch,1) + " degrees").	
	until VANG(ship:velocity:surface, ship:up:vector)>Turnpitch{
		Set ClimbAngle to  abs(vang(ship:up:vector,ship:velocity:surface)+5).
		set shipheading to lookdirup(heading(CorrectedBearing,90-Climbangle,0):vector,InitTopVec).
		set TWR to round(ship:availablethrust/(ship:mass*body:mu/(ship:altitude+body:radius)^2),2).
		SDisp("Altitude",round(ship:altitude)).
		SDisp("Speed", round(ship:velocity:surface:mag)).
		SDisp("TWR", round(TWR*Thrott,2) + " / " + TWR).
		SDisp("Pitch Angle", round(abs(vang(ship:up:vector,ship:velocity:surface)),2)).
		SUpdate().	
	}	
	SLog("Gravity Turn completed at " +round(ship:velocity:surface:mag,1) + " m/s").	
	SLog("Climb to Apoapsis " + FS:InitialAlt + "m").	
	
	//Setup PID for AP chase
	set kp to 0.1. 
	set ki to 0.01.  
	set kd to 0.05.  
	Set PID to PIDLOOP(kp,ki,kd).
	set pid:setpoint to ApLead.  //seconds to Apoapsis
	set pid:maxoutput to 0.1. 
	set pid:minoutput to -0.1.  

list parts in partlist.
if partlist:length<50{
	physics(1).
}

	Local NoseDown to False.
	when ship:Q<0.001 then{
		DeployFairing().
		Wait 1.
		set Nosedown to True.
	}

	//Climb
	Local CurrentBearing to LaunchBearing.
	set initTopVec to ship:facing:topvector.
	
	Until ship:apoapsis>FS:InitialAlt or vdot(ship:up:forevector,ship:velocity:surface)<0 {
		Set ClimbAngle to  min(vang(ship:up:vector,ship:velocity:surface),88).		
		if LaunchBearing>10 and LaunchBearing<350 {  //Ignore corrections if polar, need to sort this later.
			set CurrentBearing to VecBearing(Ship:velocity:orbit).
			set CorrectedBearing to 3*LaunchBearing-2*Currentbearing.
		}		
	
		if Nosedown=false and vang(ship:up:vector,ship:velocity:surface)<85{  
			set Thrott to max(0.1,min(1,Thrott+pid:update(time:seconds,eta:apoapsis))).  
			set shipheading to lookdirup(heading(CorrectedBearing,Max(1,90-Climbangle),0):vector,InitTopVec).
		}else{
			set Thrott to 1.
			set shipheading to lookdirup(heading(CorrectedBearing,Max(1,(90-Climbangle)/2),0):vector,InitTopVec).
		}

		set TWR to round(ship:availablethrust/(ship:mass*body:mu/(ship:altitude+body:radius)^2),2).
		SDisp("Altitude",round(ship:altitude)).
		SDisp("Speed", round(ship:velocity:surface:mag)).
		SDisp("TWR", round(TWR*Thrott,2) + " / " + TWR).
		SDisp("Pitch Angle", round(abs(vang(ship:up:vector,ship:velocity:surface)),2)).
		SDisp("Heading",round(CurrentBearing,3)).	
		SDisp("Steering",round(CorrectedBearing,3)).
		SDisp("Throttle",round(thrott,4)).
		SDisp("Apoapsis",round(ship:apoapsis)).
		SDisp("ETA Apoapsis", round(eta:apoapsis)).
		SDisp("Q",round(ship:Q,4)).
		SUpdate().			
	}
	Set Thrott to 0.
	Wait 0.1. 
	SLog("Initial Apoapsis Reached").	
	
	//maintain alt if it goes too low.	
	Lock steering to ship:velocity:orbit.
	wait 0.1.
	Physics(2).
	Local EngOn to false.
	until Ship:altitude>ship:body:atm:height{.
		if ship:apoapsis<ship:body:atm:height+1000{
			set thrott to 2 * ship:Mass / max(0.1,Ship:MaxThrust).  //2m/s acc
			set EngOn to True.
		}
		if EngOn=True and ship:apoapsis>ship:body:atm:height+2000{
			set Thrott to 0.
			Set EngOn to False.
		}
		SDisp("EngOn", EngOn).
		SDisp("Apoapsis",round(Ship:apoapsis)).
		SDisp("Eta:Ap",round(eta:apoapsis)).
		SUpdate().
	}
	set Thrott to 0.	
	
	//Finalise Altitude
	
	SLog("Finalising Apoapsis to " + fs:FinalAlt + " meters"). 	
	Set Warp to 0.		
	lock steering to heading(LaunchBearing,0):vector.
	Until ship:apoapsis>FS:InitialAlt or eta:apoapsis<10 {
		ThrottSet(2,0,((FS:InitialAlt-ship:apoapsis)/20),5).
		SUpdate().
	}
	Set Thrott to 0.
	//wait 0.1.		
	wait 1.
	return true.
}

Function DeployFairing{
	set plist to ship:partsdubbedpattern("^fairingsize").
	for p in plist{
		p:getmodule("moduleproceduralfairing"):doevent("deploy").
	}
}


Function SetInitialAlt{
	if ship:body:atm:exists{
		set fs:InitialAlt to ship:body:atm:height.
	}else{
		set fs:InitialAlt to 10000.
	}
}
