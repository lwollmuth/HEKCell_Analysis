//#include  <Append Calibrator>
//#include  <Wave Arithmetic Panel>
//#include  <Multi-peak fitting 1.4>



Function HillFunction(w,ConcValues) : FitFunc
	Wave w
	Variable ConcValues

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(ConcValues) = 1/(1 + (ec50/ConcValues)^hill)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ ConcValues
	//CurveFitDialog/ Coefficients 2
	//CurveFitDialog/ w[0] = hill
	//CurveFitDialog/ w[1] = ec50

	return 1/(1 + (w[1]/ConcValues)^w[0])
End

Function Boltzmann(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = Gmax/(1 + exp((x - Voltage50)/slope))
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 3
	//CurveFitDialog/ w[0] = Gmax
	//CurveFitDialog/ w[1] = Voltage50
	//CurveFitDialog/ w[2] = slope

	return w[0]/(1 + exp((x - w[1])/w[2]))
End
