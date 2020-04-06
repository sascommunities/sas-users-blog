/* Defining FCMP function */
proc fcmp outlib=work.fcmp.pyfuncs;
	/* Defining name and arguments of the Python function to be called */

	function Score_Python(CLAGE, CLNO, DEBTINC, DELINQ, DEROG, LOAN, MORTDUE, NINQ, VALUE, YOJ);
		/* Python object */
		declare object py(python);

		/* Getting Python file  */
		rc = py.infile("C:\assets\script.py");

		/* Send code to Python interpreter */
		rc = py.publish();
		
		/* Call python function with arguments */
		rc = py.call("score_predictions",CLAGE, CLNO, DEBTINC, DELINQ, DEROG, LOAN, MORTDUE, NINQ, VALUE, YOJ);

		/* Pass Python results to SAS variable */
		MyFCMPResult = py.results["scored"];

		return(MyFCMPResult);
	endsub;
run;

options cmplib=work.fcmp;

/* Calling FCMP function from data step */
data work.hmeq_scored;
	set work.IMPORTED_DATA;
	scored_bad = Score_Python(CLAGE, CLNO, DEBTINC, DELINQ, DEROG, LOAN, MORTDUE, NINQ, VALUE, YOJ);
	put scored_bad=;
run;
