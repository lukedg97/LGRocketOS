PRINT "LGRocketOS-0.1 Launched.".
IF ALTITUDE > 500 {
  PRINT "ABORT SEQUENCE ENGAGED."
  COPY LGRocketOS.abort.ks FROM 0.
  RUN LGRocketOS.abort.ks.
}ELSE{
  COPY LGRocketOS.launch.ks FROM 0.
  RUN LGRocketOS.launch.ks.
}
