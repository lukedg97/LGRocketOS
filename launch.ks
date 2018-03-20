PRINT "Launch Commencing...".
COPYPATH("0:/LGRocketOS/DragonI.ks", "").
LOCK THROTTLE TO 1.0.
LOCK STEERING TO HEADING(90,85).


//This is our countdown loop, which cycles from 10 to 0
HUDTEXT("Counting down:", 1, 2, 50, WHITE, false).
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    HUDTEXT("..." + countdown, 1, 2, 50, WHITE, false).
    WAIT 1. // pauses the script here for 1 second.
}

STAGE.
UNTIL ALTITUDE > 10000 {
  CheckStage().
}
WAIT 0.2.
LOCK STEERING TO HEADING(90,45).
WAIT 0.5.
UNTIL APOAPSIS > 80000 {
  CheckStage().
}
Lock THROTTLE To 0.
LOCK STEERING TO HEADING(90,0).
PRINT "Coast to APOAPSIS".
UNTIL ETA:APOAPSIS < 20 {
  PRINT "Time to Maneuver" + (ETA:APOAPSIS - 20).
  WAIT 1.
}
Lock THROTTLE To 1.
WAIT UNTIL PERIAPSIS > 50000 OR STAGE:LIQUIDFUEL < 0.1.
SafeStage().
WAIT UNTIL PERIAPSIS > 70000.
Lock THROTTLE To 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

//DragonI
RUN DragonI.ks.

FUNCTION CheckStage {
  IF STAGE:SOLIDFUEL < 0.1 AND STAGE:LIQUIDFUEL < 0.1 {
    SafeStage().
  }
  WAIT 0.1.
}

FUNCTION SafeStage {
  LOCK THROTTLE TO 0.
  WAIT 0.5.
  STAGE.
  WAIT 0.1.
  LOCK THROTTLE TO 1.
}
