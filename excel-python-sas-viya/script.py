def score_predictions(CLAGE, CLNO, DEBTINC,DELINQ, DEROG, LOAN, MORTDUE, NINQ,VALUE, YOJ):
	"Output: scored"
	# Imporing libraries
	import pandas as pd
	from sklearn.preprocessing import OneHotEncoder
	from sklearn.compose import ColumnTransformer
	from sklearn.externals import joblib

	# Create pandas dataframe with input vars
	dataset = pd.DataFrame({'CLAGE':CLAGE, 'CLNO':CLNO, 'DEBTINC':DEBTINC, 'DELINQ':DELINQ, 'DEROG':DEROG, 'LOAN':LOAN, 'MORTDUE':MORTDUE, 'NINQ':NINQ, 'VALUE':VALUE, 'YOJ':YOJ}, index=[0])

	X = dataset.values

	# Import model pickle file
	loaded_model = joblib.load("C://assets/hmeq_model.sav")

	# Score the input dataframe and get 0 or 1 
	scored = int(loaded_model.predict_proba(X)[0,1])

	# Return scored dataframe
	return scored