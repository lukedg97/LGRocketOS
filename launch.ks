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
SET launchstages TO 2.
Launch(90, LP, 80000, 2).


/////////////////////////////////
// Launch Profile:
// List(APOAPSIS, HEADING, THRUST, ...)
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
  LOCK THROTTLE TO 0.6.
  STAGE.

  //Wait to be above 10,000m to gravity turn.
  UNTIL ALTITUDE > 10000 {
    CheckStage().
  }
  LOCK THROTTLE TO 1.
  PRINT("Above 10000, assuming launch profile.").

  //Launch Profile
  SET i TO 1.
  SET mark TO time:seconds.
  FROM {local i is 1.} UNTIL i >= launchProfile:LENGTH STEP {set i to i+2.} DO {
    IF launchProfile[i-1] < finalAlt AND APOAPSIS < finalAlt {
      UNTIL (APOAPSIS > launchProfile[i-1] AND time:seconds > (mark + 5)) OR APOAPSIS > finalAlt {
        CheckStage().
        IF APOAPSIS > finalAlt{ BREAK. }
        WAIT 0.1.
      }
      SET mark TO time:seconds.
      SET head TO HEADING(compassHeading,launchProfile[i]).
      LOCK STEERING TO head.
      PRINT "Steering to " + launchProfile[i].
    }
  }
  //IF finalAlt > 0 { //0 if no max ALTITUDE. not finished
    UNTIL APOAPSIS > finalAlt{
      CheckStage().
      WAIT 0.1.
    }
    LOCK THROTTLE TO 0.
    LOCK STEERING TO HEADING(compassHeading,-5).
    PRINT "APOAPSIS: " + finalAlt.
  //}
  //Coast To APOAPSIS

  PRINT "Steering to Horizon. Coast to APOAPSIS".
  WAIT UNTIL ALTITUDE > 70000 AND STAGE:SOLIDFUEL < 0.1.
  //Eventually create a function that will maintain the apoapsis height by
  //moving the heading down or up along the horizon.
  WAIT 1.

  kuniverse:timewarp:warpto(time:seconds + ETA:APOAPSIS - 20).
  WAIT ETA:APOAPSIS - 20.
  PRINT "Circularizing...".
  LOCK STEERING TO HEADING(compassHeading, 0).
  LOCK THROTTLE TO 1.
  UNTIL PERIAPSIS > 60000 { CheckStage(). }
  EndLaunch().
  UNTIL PERIAPSIS > finalAlt { CheckStage(). }
  LOCK THROTTLE TO 0.
  PRINT "Launch Complete.".
  UNLOCK THROTTLE.
  UNLOCK STEERING.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
  SHUTDOWN.

}

FUNCTION EndLaunch {
  SET THROTTLE TO 0.
  UNTIL launchstages > 0 {
    SafeStage().
    SET launchstages TO launchstages-1.
    Wait 0.1.
  }
  SET INLAUNCH TO FALSE.
  SET THROTTLE TO 1.0.
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
