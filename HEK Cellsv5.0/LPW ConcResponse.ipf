#pragma rtGlobals=1		// Use modern global access method.

//************************************************************
//Analysis of Concentration-response recordings. 

//************************************************************
//***Define wave to be analyzed for conc-response curve
//Routines not rigorously tested or devised for general usage.

Function DRecord()
	String RawWavetoAnalyze
	Prompt RawWavetoAnalyze,"Analysis record to refine?",popup WaveList("*",";","")
		DoPrompt "Enter requested information", RawWavetoAnalyze
			if (V_Flag)
				return -1											// User canceled
			Endif	

	Duplicate/O $RawWavetoAnalyze, temp_wave
	temp_wave = temp_wave * 10^12

	Variable maxpoints = 0
	Wavestats/Q temp_wave										//define number of points in wave of interest
		maxpoints = V_npnts

	Rename temp_wave,rawwave
	Display/W = (10,10,1000,600) rawwave
//		SetAxis bottom *,maxpoints
//		SetAxis left -100,100
		ModifyGraph standoff=0
		ModifyGraph zero(left)=1
		
//	DoWindow/K Table1

END																	//END DRecord	

//************************************************************
//***Display wave

Function DRecord2()
	String RawWavetoAnalyze
	Prompt RawWavetoAnalyze,"Analysis record to refine?",popup WaveList("*",";","")
		DoPrompt "Enter requested information", RawWavetoAnalyze
			if (V_Flag)
				return -1											// User canceled
			Endif	

	Duplicate/O $RawWavetoAnalyze, temp_wave
//	temp_wave = temp_wave * 10^12

//	Rename temp_wave,rawwave
	Display/W = (10,10,1000,600) temp_wave
//		SetAxis bottom *,maxpoints
//		SetAxis left -100,100
		ModifyGraph standoff=0
		ModifyGraph zero(left)=1
		
//	DoWindow/K Table1

	ShowInfo

END																	//END DRecord	


//This macro defines the regions that will be used to measure the leak current and the glutamate-activated current.
//These values will be shown on plot as 'MarkerBars' {leak in black, peak currents in green}.

Macro CRIntervals(AnalWavename,NumberApplns,ApplnDuration,DurationCorrect,StartAnal,BaseWind,PeakWind)
	String AnalWavename=GAnalWavename
	Variable NumberApplns=GNumberApplns
	prompt NumberApplns, "Number of Glutamate Concentrations"
	Variable ApplnDuration=GApplnDuration
	prompt ApplnDuration, "Approximate Duration of Glutamate Applns (s)"
	Variable StartAnal=GStartAnal
	prompt DurationCorrect, "Small Correction for Shorter Intervals (s)"
	Variable DurationCorrect=GDurationCorrect
	prompt StartAnal, "Appoximate Start Time"
	Variable BaseWind=GBaseWind									//Defines size of baseline
	Variable PeakWind=GPeakWind									//Defines size of peak 

		Silent 1; PauseUpdate
	
	GNumberApplns=NumberApplns							//These definitions allow same paramters to be used when RE-Defining Points			
	GStartAnal=StartAnal
	GApplnDuration=ApplnDuration
	GStartAnal=StartAnal
	GDurationCorrect=DurationCorrect
	GBaseWind=BaseWind
	GPeakWind=PeakWind
	
	Display/W=(10,10,600,300) $AnalWavename					//Displays Concentration Wave...
	
	Make/O/N=(4) BaseAmpTime
	Make/O/N=(NumberApplns*2) PeakAmpTime
	
//	Variable amplpre,amplpost									//Current amplitude windows 
//	Variable counter,delta,start,ende,subcounter,intcounter		//Misc. variables
//	Variable increment,endpoint

	Variable counter,intcounter
	Variable increment,endpoint
	Variable EndPreBaseline,StartPostBaseline,StartPeak

//used variable/strings...
	Variable scalemin,scalemax
	String BaseMarker,BaseMarker2,PeakMarker,PeakMarker2		
	
	counter=1
//	subcounter=100											//Counter to finding current amplitude differences
//	delta=10
//	start=StartAnal
//	ende=StartAnal+delta-1
//	increment=1												//Counter to define step of average windows
//	intcounter=0												//Counter to set markers

	Wavestats/Q $AnalWavename								//Obtain basic information about wave being analyzed
		endpoint=V_npnts
	Wavestats/Q/R=[50,endpoint-10] $AnalWavename			//Select narrower range to avoid peaks at end
		scalemin=floor(V_min)-100								//Scale plot
		scalemax=floor(V_max)+100
		SetAxis left scalemin,scalemax
		
	Make/O/N=2 MarkerLines									//Defines size of marker bars
		MarkerLines[0]=scalemax
		MarkerLines[1]=scalemin	
	
//Approximate times for Baseline...
	intcounter=0
				
	do														//Counter/intcounter
		Basemarker="Base"+num2str(intcounter)				//Creates waves for beginning (odd numbers) and
		Basemarker2="Base"+num2str(intcounter+1)			//end (even numbers) of X values (time) for marker bars. 
			Duplicate/O MarkerLines $Basemarker		
			Duplicate/O MarkerLines $Basemarker2
			
			if (intcounter==0)
				EndPreBaseline=StartAnal + BaseWind 
				
				BaseAmpTime[intcounter]=StartAnal				//Pre Baseline
				BaseAmpTime[intcounter+1]=EndPreBaseline
		
			else
				StartPostBaseline=EndPreBaseline + (NumberApplns)*ApplnDuration
				
				BaseAmpTime[intcounter]=StartPostBaseline		//Post Baseline
				BaseAmpTime[intcounter+1]=StartPostBaseline + BaseWind
			endif
			
			SetScale/I x BaseAmpTime[intcounter],BaseAmpTime[intcounter]+0.01,"", $BaseMarker
				Append $BaseMarker
				ModifyGraph rgb($BaseMarker)=(0,0,0)
			SetScale/I x BaseAmpTime[intcounter+1],BaseAmpTime[intcounter+1]+0.01,"", $BaseMarker2
				Append $BaseMarker2
				ModifyGraph rgb($BaseMarker2)=(0,0,0)
					
		intcounter+=2		

	while (intcounter<(2*2))			
	
//Approximate times for Peaks...
	intcounter=0
	counter=1
	
	do			
		
		PeakMarker="Peak"+num2str(intcounter)
		PeakMarker2="Peak"+num2str(intcounter+1)
			Duplicate/O MarkerLines $PeakMarker
			Duplicate/O MarkerLines $PeakMarker2
			
			StartPeak=EndPreBaseline+ counter*ApplnDuration 
			StartPeak=Startpeak - (counter-1) * DurationCorrect
			
				PeakAmpTime[intcounter]=StartPeak
				PeakAmpTime[intcounter+1]=StartPeak+PeakWind
						
				SetScale/I x PeakAmpTime[intcounter],PeakAmpTime[intcounter]+0.01,"", $PeakMarker
					Append $PeakMarker
					ModifyGraph rgb($PeakMarker)=(0,65535,0)
				SetScale/I x PeakAmpTime[intcounter+1],PeakAmpTime[intcounter+1]+0.01,"", $PeakMarker2
					Append $PeakMarker2
					ModifyGraph rgb($PeakMarker2)=(0,65535,0)
									
		counter+=1			
		intcounter+=2

	while (intcounter<(NumberApplns*2))									//For-while 

	Gxaxis_max=V_minloc+50

	DoWindow/C/F Win_AnalTemp											//Scale plot to emphasize ROI
		SetAxis bottom StartAnal-50,StartPostBaseline+50
		Label bottom "time (seconds)"
		Label left "Current (nA)"
//		Show Info

	//**Routine to define last baseline					//
//		Basemarker="Base"+num2str(intcounter)
//		Basemarker2="Base"+num2str(intcounter+1)
//			Duplicate/O MarkerLines $Basemarker		
//			Duplicate/O MarkerLines $Basemarker2
			
//			BaseAmpTime[intcounter]=endpoint-BaseBack-BaseWind
//			BaseAmpTime[intcounter+1]=endpoint-BaseBack
					
//				SetScale/I x BaseAmpTime[intcounter],BaseAmpTime[intcounter]+0.01,"", $BaseMarker
//					Append $BaseMarker
//					ModifyGraph rgb($BaseMarker)=(0,0,0)
//				SetScale/I x BaseAmpTime[intcounter+1],BaseAmpTime[intcounter+1]+0.01,"", $BaseMarker2
//					Append $BaseMarker2
//					ModifyGraph rgb($BaseMarker2)=(0,0,0)

	Edit/W=(10,350,600,520)  BaseAmpTime,PeakAmpTime										//Puts table of time points on desktop
	DoWindow/C/F Time_Intervals
	
End Macro()

//***********************************************************************
//Macro updates display of Baseline and Peak Intervals

Macro CRUpdateIntervals()

	String BaseMarker,BaseMarker2,PeakMarker,PeakMarker2
	variable intcounter		

	intcounter=0
		do		

			Basemarker="Base"+num2str(intcounter)
			Basemarker2="Base"+num2str(intcounter+1)
								
				SetScale/I x BaseAmpTime[intcounter],BaseAmpTime[intcounter]+0.01,"", $BaseMarker
				SetScale/I x BaseAmpTime[intcounter+1],BaseAmpTime[intcounter+1]+0.01,"", $BaseMarker2
	
			intcounter+=2

		while (intcounter<(4))									//For-while 


	intcounter=0
		do		

			Peakmarker="Peak"+num2str(intcounter)
			Peakmarker2="Peak"+num2str(intcounter+1)
	
				SetScale/I x PeakAmpTime[intcounter],PeakAmpTime[intcounter]+0.01,"", $PeakMarker
				SetScale/I x PeakAmpTime[intcounter+1],PeakAmpTime[intcounter+1]+0.01,"", $PeakMarker2
	
		intcounter+=2

		while (intcounter<(GNumberApplns*2))									//For-while 


end UpdateIntervals()

//***********************************************************************
//Macro defines and subtracts baseline. Then determines peak glutamate-activated current.
//Originally written by SS; Modified by LPW (Summer, 2003). Developed for CR curves by LPW & ACH (Fall, 2006)

Macro CRAnalysis(AnalWavename,NumberApplns)
	String AnalWavename
	prompt AnalWavename,"Name of wave"
	Variable NumberApplns = 7
	prompt NumberApplns,"Number of Intervals"

	Variable FitPointNumber = 0
	Variable intcounter,ssintcounter
	Variable counter2 = 0
	Variable counter3 = 0
	Variable lastpt = -1
	Variable Approval = 0
	Variable xaxis_min,xaxis_max,yaxis_min,yaxis_max						//Variables for plotting
	Variable toplocation, bottomlocation

//	String subtwavename,win_subtwave,leakvaluename,peakvaluename,peakamptimename	
	String subtwavename,win_subtwave,leakvaluename,peakvaluename,peakamptimename
		
	DoWindow/K Win_AnalTemp											//Remove PointExtract Window

		Silent 1

		subtwavename="CRWave_Subt"
		win_subtwave="Win_CRWave"
		leakvaluename="CRWaveLeak"
		peakvaluename="CRWaveAmpl"	
		peakamptimename="CRPeakAmpTIme"

			toplocation = 280; bottomlocation = 520	

	Make/N=(NumberApplns) /O $PeakValueName
	Make/N=(NumberApplns) /O $PeakAmpTimeName
	Make/N=(NumberApplns) /O ConcValues
		ConcValues[1]=0.03
		ConcValues[2]=0.1
		ConcValues[3]=0.3
		ConcValues[4]=1
		ConcValues[5]=3
		ConcValues[6]=10
		ConcValues[7]=30
		
	
	Duplicate/O $AnalWavename $subtwavename
	
	Display/W=(10,toplocation,450,bottomlocation) $subtwavename			//Wave that will be analyzed
		DoWindow/C/F $win_subtwave
		Label bottom "time (seconds)"
		Label left "Current (nA)"
	
//*This routine finds the leak current amplitudes to be fitted. Derived from time points defined in PointExtraction.
//***This is a special routine used for just Pre- & Post- baseline.
	Variable startpt,endpt,PrePostcounter
		PrePostcounter=2
		intcounter=0
		
		Make/N=(PrePostcounter) /O $LeakValueName
		Make/N=(PrePostcounter) /O leakwave
		Make/N=(PrePostcounter) /O leakwavetime

		ssintcounter=0

	do
		startpt=BaseAmpTime[intcounter]
		endpt=BaseAmpTime[intcounter+1]
			
		WaveStats/Q/R=(startpt,endpt) $subtwavename				//Determines value of leak current
			$LeakValueName[intcounter/2]=V_avg	

			leakwavetime[ssintcounter] = (startpt + endpt)/2
			leakwave[ssintcounter] = V_avg

		ssintcounter +=1
		intcounter += 2

	while (intcounter < (PrePostcounter+2))

	DoWindow/F $win_subtwave
		AppendToGraph leakwave vs leakwavetime							//Points to be fitted
		ModifyGraph mode(leakwave)=2,rgb(leakwave)=(0,0,65535)
	
//*Fitting routine
//	do
//		InputDegree()														//Input to define number of polynomial fit.
			CurveFit line, leakwave /X=leakwavetime /D
			Duplicate /O $AnalWavename BaselineWave
			Duplicate /O $AnalWavename $subtwavename
			BaselineWave = poly(W_coef,x)
			ModifyGraph rgb(fit_leakwave)=(1,52428,26586)
			
//		Agreement()
//		Approval = YesOrNo
//	while(Approval != 1)
	
	$subtwavename = $AnalWavename - BaselineWave 						//Subtracted wave
	
		Wavestats/Q $AnalWavename										//Routine to focus plot on ROI
			yaxis_min=floor(V_min)-100	
			yaxis_max=500
		SetAxis left yaxis_min,yaxis_max
		ModifyGraph zero(left)=4

			xaxis_min=BaseAmpTime[0]								//Should round out...
			xaxis_max=BaseAmpTime[3]
						
		SetAxis bottom xaxis_min,xaxis_max
		RemoveFromGraph fit_leakwave,leakwave

//* Subtracted wave is now available.
//*This routine finds the peak current amplitudes. Derived from time points defined in PointExtraction. 
	intcounter=0
	counter2=0
	
	do																//Routine to determine number of points for peak waves.
		startpt=PeakAmpTime[intcounter]
		endpt=PeakAmpTime[intcounter+1]
			counter2 += (1 + endpt - startpt)
		intcounter += 2
		
	while (intcounter < (NumberApplns*2))
	
	FitPointNumber = counter2

	Make/N=(FitPointNumber) /O peakwave								//Waves for displaying Peak current values
	Make/N=(FitPointNumber) /O peakwavetime

Variable	tempcounter1=0
	intcounter=0
	counter3=0

	do
		startpt=PeakAmpTime[intcounter]
		endpt=PeakAmpTime[intcounter+1]
		
			WaveStats/Q/R=(startpt,endpt) $subtwavename				//Determines value of peak current
			$PeakValueName[intcounter/2]=V_avg	
			TextBox /F=0/B=1/A=LB/X=(intcounter*6)/Y=0 ""+num2str($PeakValueName[intcounter/2]) + "nA"
			
			$PeakAmpTimeName[intcounter/2]=(startpt+endpt)/2			//Definition of time of peak current amplitude. Uses average value.

			counter2 = 0
				
			do														//Creates waves for display
			
				peakwavetime[counter3] = startpt + counter2
				peakwave[counter3] = V_avg
					
					counter3 += 1
					counter2 += 1

			while (counter2 < (1 + endpt - startpt))
		
		tempcounter1 += 1
				
		intcounter +=2
	
	while (intcounter < (NumberApplns*2))

//* Subtracted wave is now available.	
	DoWindow /F $win_subtwave										//Accesses active window
			
	Duplicate/O peakwavetime xwavepost
	Duplicate/O peakwave ywavepost
	Append ywavepost vs xwavepost
		ModifyGraph mode(ywavepost)=2,rgb(ywavepost)=(0,0,65535)
	DoWindow/F/K Time_Intervals
	
	DoWindow/F Win_PreWave
	DoWindow/F Win_CRWave
			
	YAxisScale()
		DoWindow/F Win_PreWave
		SetAxis left Gyminvalue,Gymaxvalue 
		DoWindow/F Win_PostWave
		SetAxis left Gyminvalue,Gymaxvalue 

	Duplicate/O $PeakValueName NormCRWaveAmpl

	NormCrWaveAmpl=NormCRWaveAmpl/NormCRWaveAmpl[7]
	
	Edit $PeakAmpTimeName,ConcValues,$PeakValueName,NormCrWaveAmpl
	DoWindow/C/F CRValues
				
	Display NormCrWaveAmpl vs ConcValues
		DoWindow/C/F NormCRCurve
		ModifyGraph log(bottom)=1
		ModifyGraph mode=3,marker=8,rgb=(0,0,0)

		SetAxis left 0,1.2 
		Label left "Norm Current Amplitudes"
		Label bottom "[glu], mM"
	
	KillWaves/A/Z														//Eliminating unused waves

	Make/O/D/n=2 W_coef
		W_coef[0]=1.5
		W_coef[1]=0.01

	FuncFit/X=1 HillFunction W_coef  NormCRWaveAmpl /X=ConcValues /D 
		DoWindow/F Win_PreWave
		TextBox /F=0/B=1/A=LB/X=50/Y=50 "EC50 = "+ num2str(round(10000*W_coef[1])/10000) + "mM"
		TextBox /F=0/B=1/A=LB/X=50/Y=40 "hill coeff = "+ num2str(round(100*W_coef[0])/100)

End Macro()

//***********************************************************************
//Macro is pretty simple...used only for inputting old raw data for conc-response curves (Sasha's old data)
//Written by LPW (Winter, 2007).

Macro CRIndAnalysis()

//	Make/O/N=7 ConcValues
//		ConcValues[1]=0.03
//		ConcValues[2]=0.1
//		ConcValues[3]=0.3
//		ConcValues[4]=1
//		ConcValues[5]=3
//		ConcValues[6]=10
//		ConcValues[7]=30
//	Make/N=7  CrWaveAmpl

//	Duplicate/O CrWaveAmpl NormCrWaveAmpl

Duplicate/O wave0 NormCrWaveAmpl

//	NormCrWaveAmpl=CrWaveAmpl/CrWaveAmpl[6]
	
NormCrWaveAmpl=wave0/wave0[6]
	
	Display NormCrWaveAmpl vs ConcValues
	ModifyGraph log(bottom)=1
	ModifyGraph mode=3,marker=8,rgb=(0,0,0)

	Make/O/D/n=2 W_coef
		W_coef[0]=1.5
		W_coef[1]=0.01

	FuncFit/X=1 HillFunction W_coef  NormCRWaveAmpl /X=ConcValues /D 
		DoWindow/F Win_PreWave
		TextBox /F=0/B=1/A=LB/X=50/Y=50 "EC50 = "+ num2str(round(100*W_coef[1])/100) + "uM"
		TextBox /F=0/B=1/A=LB/X=50/Y=40 "hill coeff = "+ num2str(round(100*W_coef[0])/100)

End Macro()