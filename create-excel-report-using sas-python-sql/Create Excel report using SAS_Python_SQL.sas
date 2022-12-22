*********************************************************************;
* Create an Excel Report Using SAS, Python and SQL                  *;
*********************************************************************;

*********************************;
* Set folder path and file name *;
*********************************;
%let path=/*Enter folder path */;
%let xlFileName = myExcelReport.xlsx;


****************;
* Prepare data *;
****************;
data work.cars;
	set sashelp.cars;
	MPG_Avg=mean(MPG_City, MPG_Highway);
	drop Wheelbase Weight Length;
run;


***************************************; 
* Create the Microsoft Excel workbook *;
***************************************; 
ods excel file="&path./&xlFileName" 
		  style=ExcelMidnight   
		  options(embedded_titles="on");

***************;
* WORKSHEET 1 *;
***************;
* Print the data using SAS *;
ods excel options(sheet_name='Data' sheet_interval='none');
title height=16pt color=white "Detailed Car Data";
proc print data=work.cars noobs;
run;


***************;
* WORKSHEET 2 *;
***************;
ods excel options(sheet_name='Origin_MPG' sheet_interval='now');
title justify=left height=16pt color=white "Analyzing MPG by Each Car Origin";

* Create violin plots using Python *;
proc python;
submit;

##
## Import packages and options
##

import pandas as pd
import matplotlib.pyplot as plt
plt.style.use('fivethirtyeight')
outpath = SAS.symget('path')

##
## Data prep for the visualization
##

## Load the SAS table as a DataFrame
df = (SAS
      .sd2df('work.cars')                 ## SAS callback method to load the SAS data set as a DataFrame
      .loc[:,['Origin','MPG_Avg']]        ## Keep the necessary columns
)

 
## Create a series of MPG_Avg for each distinct origin for the violin plots
listOfUniqueOrigins = df.Origin.unique().tolist()

mpg_by_origin = {}
for origin in listOfUniqueOrigins:
    mpg_by_origin[origin] = df.query(f'Origin == @origin ').MPG_Avg

 
##
## Create the violin plots
##

## Violin plot
fig, ax = plt.subplots(figsize = (8,6))
ax.violinplot(mpg_by_origin.values(), showmedians=True)

## Plot appearance
ax.set_title('Miles per Gallon (MPG) by Origin')
rename_x_axis = {'position': [1,2,3], 'labels':listOfUniqueOrigins}
ax.set_xticks(rename_x_axis['position'])
ax.set_xticklabels(rename_x_axis['labels']);

## Save and render image file
SAS.pyplot(plt, filename='violinPlot',filepath=outpath)

endsubmit;
quit;
title;


* SQL Aggregation *;
title justify=left "Average MPG by Car Makes";
proc sql;
select Origin, round(mean(MPG_Avg)) as AverageMPG
	from work.cars
	group by Origin
	order by AverageMPG desc;
quit;
title;


* Add text *;
proc odstext;
	heading 'NOTES';
	p 'Using the SASHELP.CARS data. The following car Origins were analyzed:';
	list ;
      item 'Asia';
      item 'Europe';
	  item 'USA';
   end;    
	p 'Created by Peter S';
quit;



***************************************; 
* Close the Microsoft Excel workbook  *;
***************************************; 
ods excel close;