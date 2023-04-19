/* Initialize a CAS session */
cas;

/* Assign all available CAS libraries to the current session */
caslib _all_ assign;

/* Define a fileref (wtifred) to access the CSV file at the specified URL */
filename wtifred url 'https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=on&txtcolor=%23444444&ts=12&tts=12&width=1318&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=DCOILWTICO&scale=left&cosd=2018-03-27&coed=2023-03-27&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=2&ost=-99999&oet=99999&mma=0&fml=a&fq=Daily&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2023-04-04&revision_date=2023-04-04&nd=1986-01-02';

/* Import the CSV file from the URL into a SAS dataset (wti_oil_prices) */
proc import datafile=wtifred
    out=wti_oil_prices
    dbms=csv
    replace;
    getnames=yes;
run;

/* In March 2020 through July 2020, a sell-off in crude began when OPEC failed to strike a deal
   with its allies, led by Russia, about oil production cuts. That, in turn, caused Saudi Arabia
   to slash its oil prices and ramp up production. */

/* Create a new dataset called wti_oil_prices based on the existing dataset */

data wti_oil_prices;
   set wti_oil_prices;
   
   /* Add a new variable 'group' to categorize observations based on the date */
   /* If the date is between March 8, 2020, and July 1, 2020, set group to 1, otherwise set group to 2 */
  
   if "08MAR2020"D<date<="01JUL2020"D then group=1;
   else group=2;
run;

proc sort data=wti_oil_prices;
   by DATE;
run;


/*Plot the oil proce timeseries*/
options orientation = landscape;
ods graphics on / reset width=900px height=600px border=off ANTIALIASMAX=50100;
proc sgplot data=wti_oil_prices;
   scatter x=DATE y=DCOILWTICO / group=group transparency=.6;
run;

/*Add rows for missing dates. Populate the dates for added rows and set any other variables 
  on the added rows to missing */
proc timeseries data = wti_oil_prices out = wti_oil_price_fill;
   id date interval   = day
           accumulate = none
           setmiss    = missing
           format     = date9.;
   var DCOILWTICO;
run;

/* Fill in missing values in the DCOILWTICO variable using linear interpolation.*/
proc expand data=wti_oil_price_fill out=wti_oil_price_fill_int;
   convert DCOILWTICO=DCOILWTICO_INT / method=join;
   id DATE;
run;

/* Set the output display orientation and enable ODS graphics with specified dimensions and options */
options orientation = portrait;
ods graphics on / reset width=600px height=1000px border=off ANTIALIASMAX=50100;

/*Load the data and run the EMprical Mode Decomposition*/
proc iml;
    /* Read the input data: date and interpolated oil prices */
    use wti_oil_price_fill_int;
    read all var {DATE} into dates;
    read all var {DCOILWTICO_INT} into oil_prices;
    close wti_oil_prices_interp;

    /* Perform Empirical Mode Decomposition (EMD) to obtain IMFs and residual */
    optn = {10 10 .01 .001};  
    call EMD(IMF, residual, oil_prices,optn);
    print(IMF);
    title "IMFs of West Texas Intermediate Crude Prices";
    call panelSeries(dates, IMF, {'IMF1','IMF2','IMF3','IMF4','IMF5','IMF6','IMF7'}) grid="y" label={"DATE" "IMF"} NROWS=7;
    ndates=nrow(dates);
    output=shape(1,ndates,10);  
    output[,1]=dates;
    output[,2:8]=IMF;
    output[,9]=oil_prices;
    output[,10]=residual;
    varnames={'DATE' 'IMF1' 'IMF2' 'IMF3' 'IMF4' 'IMF5' 'IMF6' 'IMF7' 'DCOILWTICO_INT' 'RESIDUAL'};
    
    /* Create a new dataset with the combined data and IMFs */
    create wti_oil_price_IMF from output[colname=varnames];
    append from output;
    close; 
quit;


data casuser.train
     casuser.test
     train;
   /* Read data from the wti_oil_price_IMF dataset */  
   set wti_oil_price_IMF;
   
   /* Assign a group variable to categorize observations based on the date */
   /* If the date is between March 8, 2020, and July 1, 2020, set group to 1, otherwise set group to 2 */
   
   if "08MAR2020"D<date<="01JUL2020"D then group=1;
   else group=2;
   
   /* Split the data into training and test sets based on the specified date */
   /* If the date is on or before August 31, 2022, output the observation to the training datasets */
   
   
   if DATE le "31AUG2022"D then do;
      output casuser.train;
      output train;
   end; 
   
   /* Otherwise, output the observation to the test dataset */  
   
   else output casuser.test;
run;

%let lead=%sysevalf("27MAR2023"D-"31AUG2022"D);

ods noproctitle;
ods graphics / imagemap=on;
libname _tmpcas_ cas caslib="CASUSER";

proc tsmodel data=CASUSER.TRAIN 
		outobj=(outStat=CASUSER.OUTEST_IMF1(replace=YES) 
		outFcast=_tmpcas_.outFcastTemp(replace=YES) 
		parEst=CASUSER.OUTFOR_IMF1(replace=YES) ) seasonality=7;
	id DATE interval=Day FORMAT=_DATA_ nlformat=YES;
	var IMF1;
	require tsm;
	submit;
	declare object myModel(TSM);
	declare object mySpec(ARIMASpec);
	rc=mySpec.Open();

	/* Specify MA orders. For example: q = (1)(12) */
	array ma[3]/nosymbols;
	ma[1]=1;
	ma[2]=2;
	ma[3]=3;
	rc=mySpec.AddMAPoly(ma);
	rc=mySpec.SetOption('noint', 1);
	rc=mySpec.SetOption('method', 'CLS');
	rc=mySpec.Close();

	/* Setup and run the TSM model object */
	rc=myModel.Initialize(mySpec);
	rc=myModel.SetY(IMF1);
	rc=myModel.SetOption('lead', &lead);
	rc=myModel.SetOption('alpha', 0.05);
	rc=myModel.Run();

	/* Output model forecasts and estimates */
	declare object outFcast(TSMFor);
	rc=outFcast.Collect(myModel);
	declare object parEst(TSMPEst);
	rc=parEst.Collect(myModel);
	declare object outStat(TSMSTAT);
	rc=outStat.Collect(myModel);
	endsubmit;
run;

proc print data=CASUSER.OUTEST_IMF1 label contents="Fit statistics";
	title 'Fit statistics';
run;

ods exclude all;

proc sql;
	select max(DATE) into :maxTimeID from CASUSER.TRAIN;
quit;

ods exclude none;

proc sgplot data=_tmpcas_.outFcastTemp noautolegend 
		description="Predicted and actual values of IMF1";
	title 'Predicted and actual values of IMF1';
	xaxis label='DATE';
	yaxis label='IMF1';
	series x=DATE y=ACTUAL /lineattrs=(color=black) name="actual" 
		legendlabel="Actual";
	series x=DATE y=PREDICT /name="predict" legendlabel="Predicted";
	band x=DATE lower=LOWER upper=UPPER / transparency=0.5 name="pband" 
		legendlabel="95% Confidence Limits";
	refline &maxTimeID /axis=x label="Forecast Start";
run;

proc delete data=_tmpcas_.outFcastTemp;
run;

libname _tmpcas_;
