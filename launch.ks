PRINT "Launch Commencing...".
COPYPATH("0:/LGRocketOS/DragonI.ks", "").
LOCK THROTTLE TO 1.0.
LOCK STEERING TO HEADING(90,85).
SET launchstages TO 3.

//This is our countdown loop, which cycles from 10 to 0
HUDTEXT("Counting down:", 1, 2, 50, WHITE, false).
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    HUDTEXT("..." + countdown, 1, 2, 50, WHITE, false).
    WAIT 1. // pauses the script here for 1 second.
}
SET INLAUNCH TO TRUE.
STAGE.
SET oldThrust TO MAXTHRUST.
UNTIL ALTITUDE > 10000 {
  CheckStage().
}
WAIT 0.2.
LOCK STEERING TO HEADING(90,60).
PRINT "Steering to 60.".
WAIT 0.5.
UNTIL APOAPSIS > 60000 {
  CheckStage().
}
WAIT 0.2.
LOCK STEERING TO HEADING(90,45).
PRINT "Steering to 45.".
WAIT 0.5.
UNTIL APOAPSIS > 80000 {
  CheckStage().
}
PRINT "APOAPSIS 80,000".
Lock THROTTLE To 0.
LOCK STEERING TO HEADING(90,-5).
PRINT "Steering to Horizon. Coast to APOAPSIS".
WAIT UNTIL STAGE:SOLIDFUEL < 0.1.
SafeStage().
SET INLAUNCH TO FALSE.
LOCK STEERING TO HEADING(90,0).
WAIT UNTIL ALTITUDE > 70000.
kuniverse:timewarp:warpto(time:seconds + ETA:APOAPSIS - 20).
WAIT 1.
Lock THROTTLE To 1.
WAIT UNTIL PERIAPSIS > 70000.
Lock THROTTLE To 0.
UNLOCK THROTTLE.
UNLOCK STEERING.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SHUTDOWN.

FUNCTION CheckStage {
  IF STAGE:SOLIDFUEL < 0.1 AND STAGE:LIQUIDFUEL < 0.1 {
    SafeStage().
  }
  IF MAXTHRUST < oldThrust - 10 {
    SafeStage().
    SET oldThrust TO MAXTHRUST.
  }
  WAIT 0.1.
}

FUNCTION SafeStage {
  IF launchstages > 0 OR NOT INLAUNCH {
    LOCK THROTTLE TO 0.
    WAIT 0.5.
    STAGE.
    WAIT 0.1.
    LOCK THROTTLE TO 1.
    SET launchstages TO launchstages-1.
  }
}
