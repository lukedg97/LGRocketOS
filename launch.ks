PRINT "Launch Commencing...".
COPYPATH("0:/LGRocketOS/DragonI.ks", "").

//Launch Profile
SET LP TO LIST(30000,65,
               35000,60,
               40000,55,
               45000,50,
               50000,45,
               55000,40,
               60000,35).

//This is our countdown loop, which cycles from 10 to 0
HUDTEXT("Counting down:", 1, 2, 50, WHITE, false).
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    HUDTEXT("..." + countdown, 1, 2, 50, WHITE, false).
    WAIT 1. // pauses the script here for 1 second.
}
SET launchstages TO 3.
Launch(90, LP, 80000, 3).


/////////////////////////////////
// Launch Profile:
// List(APOAPSIS, HEADING, ...)
// SET LP TO LIST("A", "B", "C").
/////////////////////////////////
FUNCTION Launch {
  PARAMETER compassHeading.
  PARAMETER launchProfile.
  PARAMETER finalAlt.
  PARAMETER stages.

  SET INLAUNCH TO TRUE.
  SET oldThrust TO MAXTHRUST.
  LOCK STEERING TO HEADING(compassHeading,85).
  LOCK THROTTLE TO 1.
  STAGE.

  //Wait to be above 10,000m to gravity turn.
  UNTIL ALTITUDE > 10000 {
    CheckStage().
  }
  PRINT("Above 10000, assuming launch profile.").

  //Launch Profile
  SET i TO 1.
  PRINT("lp:LENGTH = " + launchProfile:LENGTH).
  FROM {local i is 1.} UNTIL i >= launchProfile:LENGTH STEP {set i to i+2.} DO {
    PRINT("i = " + i).
    IF launchProfile[i-1] < finalAlt{
      UNTIL APOAPSIS > launchProfile[i-1] {
        CheckStage().
        IF APOAPSIS > finalAlt{ BREAK. }
        WAIT 0.1.
      }
      SET head TO HEADING(compassHeading,launchProfile[i]).
      LOCK STEERING TO head.
      PRINT "Steering to " + launchProfile[i].
    }
  }

  UNTIL APOAPSIS > finalAlt{
    CheckStage().
    WAIT 0.1.
  }
  PRINT "APOAPSIS: " + finalAlt.
  //Coast To APOAPSIS
  LOCK THROTTLE TO 0.
  LOCK STEERING TO HEADING(compassHeading,-5).
  PRINT "Steering to Horizon. Coast to APOAPSIS".
  WAIT UNTIL ALTITUDE > 70000 AND STAGE:SOLIDFUEL < 0.1.
  //Eventually create a function that will maintain the apoapsis height by
  //moving the heading down or up along the horizon.
  STAGE.
  WAIT 1.
  SET INLAUNCH TO FALSE.
  kuniverse:timewarp:warpto(time:seconds + ETA:APOAPSIS - 20).
  WAIT ETA:APOAPSIS - 20.
  PRINT "Circularizing...".
  LOCK STEERING TO HEADING(compassHeading, 0).
  LOCK THROTTLE TO 1.
  UNTIL PERIAPSIS > finalAlt { CheckStage(). }
  LOCK THROTTLE TO 0.
  PRINT "Launch Complete.".
  UNLOCK THROTTLE.
  UNLOCK STEERING.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
  SHUTDOWN.

}

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
    WAIT 0.5.
    LOCK THROTTLE TO 1.
    SET launchstages TO launchstages-1.
  }
}
