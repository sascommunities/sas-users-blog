cas;
caslib _all_ assign;


/*
N: number of time periods in the series
N_init: the warmup period for AR(2) simulation
filter_hlen: floor of half of the window size for the 
             median filter

*/

%let N = 730;
%let N_init = 250;
%let p = 3;                                   
%let q = 1;
%let filter_hlen=15;

/*Simulate AR(2) model for power consumption*/
 
data CASUSER.ARMASim(keep= time y group);
   call streaminit(234333);
   array phi phi1 - phi&p (0.47, 0.30, 0.0);       /* AR coefficients   */
   array theta theta1 - theta&q (0.0);          /* MA coefficients   */
   array yLag yLag1 - yLag&p;            /* save q lagged error terms */
   array errLag errLag1 - errLag&q;      /* save p lagged values of y */

/* set initial values to zero */
   do j = 1 to dim(yLag); 
      yLag[j] = 0; 
   end;
   do j = 1 to dim(errLag); 
      errLag[j] = 0; 
   end;
   /* “steady state” method: discard first N_init observations */
   do time = 1 to &N_init+&N;
      /* y at date is a function of values and errors at previous dates*/
      intercept=0;
      e = .2*rand("Normal");
      y = intercept + e;
      do j = 1 to dim(phi);                                  
         /* AR terms */
         y = y + phi[j] * yLag[j];
      end;
      do j = 1 to dim(theta);                               
         /* MA terms */
         y = y - theta[j] * errLag[j];
      end;
      
      if time > &N_init then do;
         if time>=&N_init+&N-180 then do;
            group=2;
		 end;
		 else do;
           group=1;
		 end;
         output CASUSER.ARMASim;  
      end;


      /* update arrays of lagged values */
      do j = dim(yLag) to 2 by -1; 
         yLag[j] = yLag[j-1]; 
      end;
      yLag[1] = y;
      do j = dim(errLag) to 2 by -1; 
         errLag[j] = errLag[j-1]; 
      end;
      errLag[1] = e;
   end;
run;

data casuser.armasim;
   set CASUSER.armasim;
   time=time-&N_init;
   if group=2 then y=.5 + .15*rannor(213);
run;

/*Plot the initial series*/
proc sgplot data=CASUSER.armasim;
   series x=time y=y / group=group;
   *scatter x=time y=y / group=group;
   yaxis min=-3 max=3;
run;


/*Forecast the initial series*/
proc tsmodel
  data=CASUSER.armasim
  outobj= (
           outfor       = casuser.LS_OUTFOR   /* actual and forecast value*/
           outstat      = casuser.LS_OUTSTAT   /* forecast stat and perfomance */
           outmodelinfo = casuser.LS_MODELINFO /* selected model summary */
           parmest      = casuser.LS_PARMEST   /* selected model details */
          );
 
  *define time series ID variable and the time interval;
  id time interval = day SETMISSING=missing;
  var y;
  *using the ATSM (Automatic Time Series Model) package;
  require atsm;

  submit; 
     declare object dataframe(tsdf)   ; /* TSDF: Time series data frame used to group series variables for DIAGNOSE and FORENG objects */
     declare object diagspec(diagspec); /* DIAGSPEC: Diagnostic control options for DIAGNOSE object */
     declare object diagnose(diagnose); /* DIAGNOSE: Automatic time series model generation */
     declare object forecast(foreng)  ; /* FORENG:   Automatic time series model selection and forecasting */
  
     declare object outfor(outfor);             /* OUTFOR  : Collector for FORENG forecasts */
     declare object outstat(outstat);           /* OUTSTAT : Collector for FORENG forecast performance statistics */
     declare object outmodelinfo(outmodelinfo); /* OUTMODEL: Collector for selected model summary */
     declare object parmest(outest);            /* PARMEST : Collector for selected model details */

     array p[2]      / nosymbols; /* AR components parameters array */
     array q[2]      / nosymbols; /* MA components parameters array */
     array ps[2]     / nosymbols; /* Seasonal AR components parameters array */
     array qs[2]     / nosymbols; /* Seasonal MA components parameters array */
  
	 rc = dataframe.initialize();
     /* Target series */
     rc = dataframe.addY(y);

	 *OPEN THE DIAGSPEC OBJECT AND ENABLE ESM AND ARIMAX MODEL CLASS FOR DIAGNOSE;
     rc = diagspec.open();

     P[1]     =1;P[2]     =3; /* Nonseasonal AR order range */
     Q[1]     =1;Q[2]     =1; /* Nonseasonal MA order range */
	 PS[1]    =0;PS[2]    =0;  /* Seasonal AR order range */
	 QS[1]    =0;QS[2]    =0;  /* Seasonal MA order range */

     rc = diagspec.setARIMAX('SIGLEVEL', 0.01
                           ,'IDENTIFY','ARIMA' /* Identification order (ARIMA, REG, or BOTH) */
                           ,'NOINT',0         /* Suppress constant term (0 | 1) */
                           ,'P',P             /* Nonseasonal AR order range */
                           ,'Q',Q             /* Nonseasonal MA order range */
                           ,'PS',PS           /* Seasonal AR order range */
                           ,'QS',QS           /* Seasonal MA order range */
                           ,'CRITERION','AIC' /* Identification criterion */
                           ,'ESTMETHOD','CLS' /* ARIMA estimation method */
                           );

   /* level shift detection */
   rc=diagspec.setARIMAXOutlier('ALLOWAO',0        /*Allow additive outliers (0|1)*/
                                ,'ALLOWLS',1       /*Allow level shifts (0|1)*/
                                ,'ALLOWTLS',0      /*Allow temporary level shifts (0|1)*/
                                ,'DETECT','YES'    /*Include level shifts that improve the AIC*/
                                ,'SIGLEVEL',.01);    /* value between 0 and 1 that specifies 
                                                        the significance level for outlier detection*/
                               


   rc = diagspec.Close();

   *SET THE DIAGNOSE OBJECT USING THE DIAGSPEC OBJECT AND RUN THE DIAGNOSE PROCESS;
   rc = diagnose.initialize(dataframe);
   rc = diagnose.setSpec(diagspec);                /* use diagspec defined above to run diagnose */
   rc = diagnose.run();

   rc = forecast.initialize(diagnose); /* use diagnose result for forecasting */
   rc = forecast.setOption('ALPHA', 0.05);    /* fit statistics*/
   rc = forecast.setOption('CRITERION','GMAPE');    /* fit statistics*/
   rc = forecast.setOption('BACK',170);
   rc = forecast.setOption('LEAD',170);        
   rc = forecast.setOption('TASK','FORECAST');     /* SELECT=model selection, estimates parameters,produces forecasts
                                                      FIT=estimates parameters by using the model specified then forecasts
                                                      UPDATE=estimates parameters by using the model specified then forecasts.
                                                             UPDATE differs from FIT, parameters found in specified are used 
                                                             as starting values in estimation
                                                      FORECAST=forecasts using model and parameters specified*/

    rc = forecast.run();

   *COLLECT THE FORECAST AND STATISTIC-OF-FIT FROM THE FORGEN OBJECT RUN RESULTS;
   rc = outfor.collect(forecast);       /* OUTFOR  : load forecasts */
   rc = outstat.collect(forecast);      /* OUTSTAT : load forecast performance statistics */
   rc = outmodelinfo.collect(forecast); /* OUTMODEL: load selected model summary */
   rc = parmest.collect(forecast);      /* PARMEST : load selected model details */
  endsubmit;
quit;


/*Print out the parameter estimates from the initial model*/
proc print data=casuser.LS_PARMEST noobs label;
   var _PARM_  _LAG_ _EST_ _STDERR_ _PVALUE_;
run;


/*Plot the initial forecast from TSMODEL */
options orientation = landscape;
ods graphics on / outputfmt=png reset width=800px height=600px border=off ANTIALIASMAX=50100;
proc sgplot data=casuser.ls_outfor;
   format time z4.;
   series x=time y=ACTUAL / legendlabel="Actual"
                    lineattrs=(thickness=2 color=darkblue) ;
   series x=time y=PREDICT / legendlabel="Predicted"
                    lineattrs=(thickness=2 color=red);
   band x=time lower=lower upper=upper / transparency=.7 legendlabel="Prediction Interval";
   yaxis min=-3 max=3;
   keylegend / location=inside position=topleft ACROSS=1;                  
run;

/*Create missing actuals to add to the beginning and end of the series*/
data casuser.filter_begin_end;
   length time y 8.; 
   do time = (-&filter_hlen+1) to 0;
      call missing(y);
      output;
   end;
   do time = (&N_init+&N+1) to (&N_init+&N+&filter_hlen) ;
      call missing(y);
      output;
   end;
run;   

/*Append missing to the beginning and end of series to compute the
  centered median filter*/

data armafilter;
   set casuser.armasim
       casuser.filter_begin_end;
run;																																									


/*Order by time so centered median filter is 
  computed correctly*/
proc sort data=armafilter;
   by time;
run; 

/*Compute the median filter and the moving average*/
proc iml;
   
   use work.armafilter;
   read all var {y};
   /*Create the time and median filtered vectors*/
   t = do(1,&N, 1); 
   tt=t`;
   m = j(&filter_hlen, 1, .);
   x=dfmedfilt(y, 2*&filter_hlen+1);
   yy=y[&filter_hlen+1:&N+&filter_hlen];

   /* Simple moving average of k data values.
   First k-1 values are assigned the mean of all previous values.
   Inputs:     y     column vector of length N >= k
               k     number of data points to use to construct each average
*/
   start MA(y, k);
      MA = j(nrow(y), 1, .);
      do i = 1 to nrow(y);
         idx = max(1,(i-k+1)):i;   /* rolling window of data points */
         MA[i] = mean( y[idx] );   /* compute average */
      end;
      return ( MA );
   finish;

   /*Create the output data matrix*/
   Result = j(&N, 4, .);
   Result[,1] = t`;
   Result[,2] = yy;
   Result[,3] = x;
   Result[,4] = MA(yy,  2*&filter_hlen+1);
   varNames = {'time' 'y' 'medianFilter' 'movingAverage'};
   
   /*Write the matrix to the medianFilter dataset*/
   create medianFilter from Result[colname=varNames];
   append from Result;
   close medianFilter;   

quit;

/*Plot the original simulated series with the median filter and moveing average overlayed. 
  This shows that the median filter adjusts more rapidly to the level shift*/
options orientation = landscape;
ods graphics on / outputfmt=png reset width=800px height=600px border=off ANTIALIASMAX=50100;
proc sgplot data=medianFilter;
   series x=time y=y / transparency=.65;
   series x=time y=medianFilter / lineattrs=(thickness=2); 
   series x=time y=movingAverage / lineattrs=(thickness=2);
   keylegend / location=inside position=topleft ACROSS=1;                     
   yaxis min=-3 max=3;
run;

/*Load data back into CAS for TSMODEL*/
data casuser.medianFilter; 
   set medianFilter;
run;


/*Run the forecast on the median filtered series*/
proc tsmodel
  data=casuser.medianFilter
  outobj= (
           outfor       = casuser.median_LS_OUTFOR   /* actual and forecast value*/
           outstat      = casuser.median_LS_OUTSTAT   /* forecast stat and perfomance */
           outmodelinfo = casuser.median_LS_MODELINFO /* selected model summary */
           parmest      = casuser.median_LS_PARMEST   /* selected model details */
          );
 
  *define time series ID variable and the time interval;
  id time interval = day SETMISSING=missing;
  var medianFilter;
  *using the ATSM (Automatic Time Series Model) package;
  require atsm;

  *starting user script;
  submit; 
     declare object dataframe(tsdf)   ; /* TSDF: Time series data frame used to group series variables for DIAGNOSE and FORENG objects */
     declare object diagspec(diagspec); /* DIAGSPEC: Diagnostic control options for DIAGNOSE object */
     declare object diagnose(diagnose); /* DIAGNOSE: Automatic time series model generation */
     declare object forecast(foreng)  ; /* FORENG:   Automatic time series model selection and forecasting */
  
     declare object outfor(outfor);             /* OUTFOR  : Collector for FORENG forecasts */
     declare object outstat(outstat);           /* OUTSTAT : Collector for FORENG forecast performance statistics */
     declare object outmodelinfo(outmodelinfo); /* OUTMODEL: Collector for selected model summary */
     declare object parmest(outest);            /* PARMEST : Collector for selected model details */

     array p[2]      / nosymbols; /* AR components parameters array */
     array q[2]      / nosymbols; /* MA components parameters array */
     array ps[2]     / nosymbols; /* Seasonal AR components parameters array */
     array qs[2]     / nosymbols; /* Seasonal MA components parameters array */
  
	 rc = dataframe.initialize();
     /* Target series */
     rc = dataframe.addY(medianFilter);

	 *OPEN THE DIAGSPEC OBJECT AND ENABLE ESM AND ARIMAX MODEL CLASS FOR DIAGNOSE;
     rc = diagspec.open();

      Q[1]     =1;Q[2]     =2; /* Nonseasonal MA order range */
	 PS[1]    =1;PS[2]    =2;  /* Seasonal AR order range */
	 QS[1]    =0;QS[2]    =0;  /* Seasonal MA order range */

     rc = diagspec.setARIMAX('SIGLEVEL', 0.01
                           ,'IDENTIFY','ARIMA' /* Identification order (ARIMA, REG, or BOTH) */
                           ,'NOINT',0         /* Suppress constant term (0 | 1) */
                           ,'Q',Q             /* Nonseasonal MA order range */
                           ,'PS',PS           /* Seasonal AR order range */
                           ,'QS',QS           /* Seasonal MA order range */
                           ,'CRITERION','AIC' /* Identification criterion */
                           ,'ESTMETHOD','CLS' /* ARIMA estimation method */
                           );

 /* level shift detection */
   rc=diagspec.setARIMAXOutlier('ALLOWAO',0        /*Allow additive outliers (0|1)*/
                                ,'ALLOWLS',1       /*Allow level shifts (0|1)*/
                                ,'ALLOWTLS',0      /*Allow temporaray level shifts (0|1)*/
                                ,'DETECT','YES'  /*Include level shifts that improve the AIC*/
                                ,'SIGLEVEL',.5   /*alpha level between 0 and 1 that specifies the cutoff value for outlier detection*/
                               );

   rc = diagspec.Close();

   *SET THE DIAGNOSE OBJECT USING THE DIAGSPEC OBJECT AND RUN THE DIAGNOSE PROCESS;
   rc = diagnose.initialize(dataframe);
   rc = diagnose.setSpec(diagspec);                /* use diagspec defined above to run diagnose */
   rc = diagnose.run();

   rc = forecast.initialize(diagnose); /* use diagnose result for forecasting */
   rc = forecast.setOption('ALPHA', 0.05);    /* fit statistics*/
   rc = forecast.setOption('CRITERION','GMAPE');    /* fit statistics*/       
   rc = forecast.setOption('TASK','FORECAST');     /* SELECT=model selection, estimates parameters,produces forecasts
                                                      FIT=estimates parameters by using the model specified then forecasts
                                                      UPDATE=estimates parameters by using the model specified then forecasts.
                                                             UPDATE differs from FIT, parameters found in specified are used 
                                                             as starting values in estimation
                                                      FORECAST=forecasts using model and parameters specified*/

    rc = forecast.run();

   *COLLECT THE FORECAST AND STATISTIC-OF-FIT FROM THE FORGEN OBJECT RUN RESULTS;
   rc = outfor.collect(forecast);       /* OUTFOR  : load forecasts */
   rc = outstat.collect(forecast);      /* OUTSTAT : load forecast performance statistics */
   rc = outmodelinfo.collect(forecast); /* OUTMODEL: load selected model summary */
   rc = parmest.collect(forecast);      /* PARMEST : load selected model details */
  endsubmit;
quit;


/*Print the parameter estimates for the median filtered model*/
proc print data=casuser.median_LS_PARMEST noobs label;
   var _MODELVAR_ _PARM_  _LAG_ _EST_ _STDERR_ _PVALUE_;
run;


/*Join the initial simulated data with the median filter forecast
  so that the original actuals can plot with the median filtered forecast*/
proc fedsql sessref=casauto;
    create table plotMedFilt as
    select median_ls_outfor.time, 
           median_ls_outfor.predict, 
           median_ls_outfor.lower,
           median_ls_outfor.upper,
           armasim.y
    from CASUSER.armasim, CASUSER.median_ls_outfor
    where armasim.time = median_ls_outfor.time;
quit;   


/* PLot the actual data and median filtered forecast overlayed*/ 
options orientation = landscape;
ods graphics on / outputfmt=png reset width=800px height=600px border=off ANTIALIASMAX=50100;
proc sgplot data=casuser.plotMedFilt;
   format time z4.;
   series x=time y=y / legendlabel="Actual Standardized"
                    lineattrs=(thickness=2 color=darkblue) transparency=.7;
   series x=time y=PREDICT / legendlabel="Predicted after Median Filtering"
                    lineattrs=(thickness=2 color=red);
   yaxis min=-3 max=3;
   refline 547 550 / axis=x lineattrs=(thickness=.1 color=darkblue pattern=dot)
                     label=("Predicted Onset"  "Actual Onset") labelloc=outside;
   keylegend / location=inside position=topleft ACROSS=1;                  
run;
