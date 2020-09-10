%let BASE_URI=%sysfunc(getoption(SERVICESBASEURL));
FILENAME tranFile TEMP ENCODING='UTF-8';
FILENAME hdrout TEMP ENCODING='UTF-8';

/* transform the datasource of a report   */
/* use the transFile to hold the response body  */
PROC HTTP METHOD="POST" oauth_bearer=sas_services OUT=tranFile headerout=hdrout
	URL = "&BASE_URI/reportTransforms/dataMappedReports/?useSavedReport=true&saveResult=true"
	IN = '
			{
			  "inputReportUri": "/reports/reports/4e72e34a-f691-46d2-9c5d-859bf6d41d7d",
			  "dataSources": [
			    {
			      "namePattern": "serverLibraryTable",
			      "purpose": "original",
			      "server": "cas-shared-default",
			      "library": "HPS",
			      "table": "CARS"
			    },
			    {
			      "namePattern": "serverLibraryTable",
			      "purpose": "replacement",
			      "server": "cas-shared-default",
			      "library": "CASUSER",
			      "table": "CARS_NEW",
			      "replacementLabel": "NEW CARS",
			      "dataItemReplacements": [
			        {
			          "originalColumn": "dte",
			          "replacementColumn": "date"
			        },
			        {
			          "originalColumn": "wght",
			          "replacementColumn": "weight"
			        },	
			        {
			          "originalColumn": "dest",
			          "replacementColumn": "region"
			        }
			      ]
			    }
			  ],
			  "resultReportName": "Transformed Report 1",
			  "resultParentFolderUri": "/folders/folders/cf981702-fb8f-4c6f-bef3-742dd898a69c",
			  "resultReport": {
							    "name": "Transformed Report 1",
							    "description": "TEST report transform"
							}
			}
		';
    HEADERS "Accept" = "application/vnd.sas.report.transform+json"
			"Content-Type" = "application/vnd.sas.report.transform+json" ;
RUN;
LIBNAME tranFile json;

/* check if there is error from the transform  */
proc sql;
	select p1, p2, value
	from tranFile.alldata
	where p1="errorMessages";
quit;

/* check the messages from the transform   */
proc sql;
	select p1, p2, value
	from tranFile.alldata
	where p1="messages";
quit;

/* print the response  */
data  _null_;
	infile tranFile;
	input;
	put _infile_;
run;

/* print the response header */
data  _null_;
	infile hdrout;
	input;
	put _infile_;
run;