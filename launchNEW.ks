PRINT "Launch Commencing...".
COPYPATH("0:/LGRocketOS/DragonI.ks", "").

SET launchstages TO 2.
//Launch Profile
SET LP TO LIST(0,90,1,
               1000,85,0.8,
               10000,80,1,
               20000,75,1,
               25000,70,1,
               30000,65,1,
               35000,60,1,
               40000,55,1,
               45000,50,1,
               50000,45,1,
               55000,40,1,
               60000,35,1).

//This is our countdown loop, which cycles from 10 to 0
HUDTEXT("Counting down:", 1, 2, 50, WHITE, false).
FROM {local countdown is 3.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    HUDTEXT("..." + countdown, 1, 2, 50, WHITE, false).
    WAIT 1. // pauses the script here for 1 second.
}

Launch(90, LP, 100000, 2).


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

  launchProfile:ADD( finalAlt ).
  SET launchstages TO stages.
  SET INLAUNCH TO TRUE.
  SET oldThrust TO MAXTHRUST.
  //LOCK STEERING TO HEADING(compassHeading,85).
  //LOCK THROTTLE TO 1.
  //STAGE.


  //SET i TO 2.
  FROM {local i is 2.} UNTIL i >= launchProfile:LENGTH STEP {set i to i+3.} DO {
    SET head TO HEADING(compassHeading,launchProfile[i-1]).
    SET throt TO launchProfile[i].
    LOCK STEERING TO head.
    LOCK THROTTLE TO throt.
    IF i = 1 {
      STAGE.
    }
    PRINT "Steering to " + launchProfile[i-1] + ". Throttle to " + launchProfile[i] + ".".
    UNTIL ALTITUDE > launchProfile[i+1]{
      IF APOAPSIS > finalAlt {
        BREAK.
      }
      CheckStage().
      WAIT 0.1.
    }
  }

  // Hit final altitude
  PRINT "Final Altitude Reached, Coast to Apoapsis.".
  //Coast To APOAPSIS
  LOCK STEERING TO HEADING(compassHeading, 0).
  LOCK THROTTLE TO 0.
  WAIT UNTIL ALTITUDE > 70000 AND STAGE:SOLIDFUEL < 0.1.
  //Eventually create a function that will maintain the apoapsis height by
  //moving the heading down or up along the horizon.
  WAIT 1.
  kuniverse:timewarp:warpto(time:seconds + ETA:APOAPSIS - 45).
  WAIT ETA:APOAPSIS - 40.
  PRINT "Circularizing...".
  LOCK STEERING TO HEADING(compassHeading, 0).
  LOCK THROTTLE TO 1.
  UNTIL PERIAPSIS > 60000 { CheckStage(). }
  EndLaunch().
  UNTIL PERIAPSIS > finalAlt OR PERIAPSIS+5000 > ALTITUDE { CheckStage(). }
  LOCK THROTTLE TO 0.
  PRINT "Launch Complete.".
  UNLOCK THROTTLE.
  UNLOCK STEERING.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
  SHUTDOWN.

}

FUNCTION EndLaunch {
  LOCK THROTTLE TO 0.
  PRINT "Releasing Launch Vehicle, END LAUNCH. Launch Stages Remaining: " + launchstages.
  SET INLAUNCH TO FALSE.
  UNTIL launchstages < -1 {
    SafeStage().
    SET launchstages TO launchstages-1.
    Wait 0.1.
  }
  LOCK THROTTLE TO 1.0.
}

FUNCTION CheckStage {
  IF STAGE:SOLIDFUEL < 0.1 AND STAGE:LIQUIDFUEL < 0.1 {
    SafeStage().
  }
  IF MAXTHRUST < oldThrust - 10 {
    SafeStage().
    SET oldThrust TO MAXTHRUST.
  }
  IF MAXTHRUST < 1 {SafeStage().}
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
