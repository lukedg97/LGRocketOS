PRINT "LGRocketOS-0.3 Launched.".
COPYPATH("0:/LGRocketOS/abort.ks", "").
IF ALTITUDE > 500 {
  PRINT "ABORT SEQUENCE ENGAGED.".
  RUN abort.ks.
}ELSE{
  COPYPATH("0:/LGRocketOS/launchNEW.ks", "").
  RUN launchNEW.ks.
}
