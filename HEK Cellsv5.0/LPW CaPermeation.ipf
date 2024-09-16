//***********************************************************************
//
//Analysis of Pf Measurements...
//
//***********************************************************************
//***Routine assays Pf measurements.
//***Currrent is _I-mon
//***Mirror of piezo is _Adc-2
//***Photomultiplier signal is _Adc-0
//***Mirror of what is sent to light source is _Adc-4 

Macro PfMeasurements(GroupNo,SeriesNo,FirstSweepNo,fmax,BeadUnits)
	Variable GroupNo = GGroupNo
		prompt GroupNo, "Group number"
	Variable SeriesNo = GSeriesNo
		prompt SeriesNo, "Series number"
	Variable FirstSweepNo = GFirstSweepNo
		prompt FirstSweepNo, "First sweep number"
	Variable FMax=0.15 						//BU/pC
		prompt FMax, "fmax: "
	Variable BeadUnits = GBeadUnits
		prompt BeadUnits, "BU: "
	
	Silent 1

	GGroupNo = GroupNo
	GSeriesNo = SeriesNo
	GFirstSweepNo = FirstSweepNo
	GBeadUnits = BeadUnits
	
//Variable for basic analysis
	Variable startleak = 0.01										//parameters to define baseline for leak substraction
	Variable endleak,leakcurrent
	Variable piezostart,piezoend
	Variable thresholdlevel = 1
	Variable peakcurrentloc,mincurrent
	Variable offset = 0.005
	Variable peakcurrent,currentintegral
	
	Variable numoffurastims										//parameters to determine F340 and F380 amplitudes and time
	Variable furastimtime = 0.05
	Variable counter,beginfura340,endfura340,beginfura380,endfura380
	
	Variable rightyminvalue,yminvalue							//for routine to set right axis
	Variable rightymaxvalue,ymaxvalue	
	Variable Approval
	
	Variable startno,endno											//parameters to determine fractional Ca2+ currents
	Variable preffura380ampl,fura380fit,fura380data,deltafura380,timeofdeltafura380
	Variable fvalue,Pf
	
	String currentwave,piezowave,furawave,furastimwave	 
		
	String WaveNameBase = GWaveNameBase							//Should be 'Pulse'
	String EndNameBase = GEndNameBase							//Should be '_I-mon'
	String piezobase = "_2_Adc-2"
	String furastimbase = "_3_Adc-4"
	String furabase = "_4_Adc-0"

	String analysiswave,fura340amplwave,fura380amplwave,fura340timewave,fura380timewave
	String fitfura380,displayfura380fit,currentintegralwave

//Assigning names to waves. bpc-HEKARead version

		if (FirstSweepNo < 10)										//Needed to allow user to analyze single later traces
			currentwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_00" + num2str(FirstSweepNo) + EndNamebase
			piezowave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_00" + num2str(FirstSweepNo) + piezobase
			furastimwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_00" + num2str(FirstSweepNo) + furastimbase
			furawave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_00" + num2str(FirstSweepNo) + furabase
		else
			if (FirstSweepNo < 100)
				currentwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_0" + num2str(FirstSweepNo) + EndNamebase
				piezowave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_0" + num2str(FirstSweepNo) + piezobase
				furastimwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_0" + num2str(FirstSweepNo) + furastimbase
				furawave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_0" + num2str(FirstSweepNo) + furabase
				
			else
				currentwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_" + num2str(FirstSweepNo) + EndNamebase
				piezowave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_" + num2str(FirstSweepNo) + piezobase
				furastimwave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_" + num2str(FirstSweepNo) + furastimbase			
				furawave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo) + "_" + num2str(FirstSweepNo) + furabase
				
			endif()
		endif()

	analysiswave =  WaveNamebase + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)
	fura340amplwave =  "fura340ampl" + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)
	fura380amplwave =  "fura380ampl" + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)
	fura340timewave =  "fura340time" + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)
	fura380timewave =  "fura380time" + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)
	currentintegralwave="currentintegralwave" + "_" + num2str(GroupNo) + "_" + num2str(SeriesNo)


//**Findlevels finds the startpoint and endpoint of the PIEZO record.  These points will be used as reference for glutamate applications.
	FindLevel/EDGE=1 /Q $piezowave, thresholdlevel			//Identify start of piezo step
		piezostart = V_LevelX
		
		endleak = piezostart - 0.05								//uses piezostart time to determine leak current

	FindLevel/EDGE=2 /Q/R=(piezostart+0.01,) $piezowave, thresholdlevel		//Identify end of piezo step
		piezoend = V_LevelX
	
//**Define properties of CURRENT wave

	Duplicate/O $currentwave $analysiswave						//assigns new name to protect orginal
	
		$analysiswave = $analysiswave*10^12
		Wavestats/Q/R=(startleak,endleak) $analysiswave			//determining leak current of current wave
			leakcurrent = V_avg											//location of initial current amplitude

		$analysiswave = $analysiswave - leakcurrent

	Wavestats/Q/R=(piezostart,piezostart + 0.05) $analysiswave			//determining location of peak current
		peakcurrentloc = V_minloc

		Wavestats/Q/R=(peakcurrentloc-offset,peakcurrentloc+offset) $analysiswave
			peakcurrent = V_avg										//averages inward currents around min current loc

//**Define properties of FURASTIMWAVE & FURAWAAVE

	FindLevels /D=furastimlocations/EDGE=1/M=0.02/Q $furastimwave,thresholdlevel+1	//identifies number of fura380 stimulations
	
		numoffurastims = numpnts(furastimlocations) - 1
		
		Make/O/N=(numoffurastims) fura340amplitudes				
		Make/O/N=(numoffurastims) fura380amplitudes
		Make/O/N=(numoffurastims) fura340times				
		Make/O/N=(numoffurastims) fura380times	
		
		counter = 0
		do																//do-while to measure amplitudes of fura340 and fura380
			
			fura340times[counter] = furastimlocations[counter] + furastimtime/2		//determine time wave for fura stim pulses
			fura380times[counter] = furastimlocations[counter] - furastimtime/2
			
			beginfura340 = furastimlocations[counter] + 0.01					//determine amplitudes of fura stim pulses
			endfura340 = furastimlocations[counter] + furastimtime
			beginfura380 = furastimlocations[counter] - (furastimtime - 0.01)
			endfura380 = furastimlocations[counter] - 0.005
			
			Wavestats/Q/R=(beginfura340,endfura340) $furawave				//fill FURA340 wave
				fura340amplitudes[counter] = V_avg
		
			Wavestats/Q/R=(beginfura380,endfura380) $furawave				//fill FURA380 wave
				fura380amplitudes[counter] = V_avg
		
			counter += 1
		while (counter < numoffurastims)

	Duplicate/O fura340amplitudes $fura340amplwave					//assigns name to protect data and permit multiple waves to be analyzed
	Duplicate/O fura380amplitudes $fura380amplwave
	Duplicate/O fura340times $fura340timewave
	Duplicate/O fura380times $fura380timewave

//**Display data
		Display/W=(50,50,500,275) $furawave
			Append $fura340amplwave vs $fura340timewave
			Append $fura380amplwave vs $fura380timewave
			
			ModifyGraph mode($fura340amplwave)=3,marker($fura340amplwave)=19,rgb($fura340amplwave)=(0,0,0)
			ModifyGraph mode($fura380amplwave)=3,marker($fura380amplwave)=8,rgb($fura380amplwave)=(0,0,0)

//**Analyze current wave and fura380 wave 

		Display/W=(50,300,500,600) $analysiswave
				Label bottom "Time (sec)"
				Label left "I (pA)"

				ModifyGraph grid(bottom)=2

		Append/R $fura380amplwave vs $fura380timewave
				ModifyGraph rgb=(0,0,0),mode($fura380amplwave)=3,marker($fura380amplwave)=8
				Label right "fura380 (V)"
			
			ReorderTraces $fura380amplwave,{$analysiswave}
		
			YAxisScale()											//Set scale for F380 axis		
				rightyminvalue = Gyminvalue
				rightymaxvalue = Gymaxvalue
					SetAxis right rightyminvalue,rightymaxvalue
					
//**Determining deltaF380
		do
			signalfura()															//input for fura parameters
				startno=furabasest
				endno=furabaseend
				preffura380ampl=furasignalno

			fitfura380="fitfura380_" + num2str(GroupNo) + "_" + num2str(SeriesNo)			
			displayfura380fit="displayfurafit_" + num2str(GroupNo) + "_" + num2str(SeriesNo)

			Duplicate/O $fura380amplwave $fitfura380
				CurveFit/Q line $fura380amplwave(startno,endno) /D=$fitfura380 		//fitting line to initial F380 points 
			Duplicate/O $fitfura380 displayfit
				displayfit=K0+K1*x
			Duplicate/O displayfit $displayfura380fit
			AppendToGraph/R $displayfura380fit vs $fura380timewave					//adds fitted line to graph
				ModifyGraph mode($displayfura380fit)=0
			
			TextBox/K/N=text0

			Textbox/A=RB/X=0/Y=0/F=0 "baseline: " + num2str(furabasest)			//adding baseline fit parameters to graph
			Appendtext "baseline: " + num2str(furabaseend)
			Appendtext "fura380ampl:" + num2str(furasignalno)
			Appendtext "slope:" + num2str(K1)
			
			Agreement()												//Verify that baseline fit OK...
				Approval = YesOrNo

		while(Approval !=1)


	//Determining delta380
		fura380fit = $displayfura380fit[preffura380ampl]
		fura380data = ($fura380amplwave[preffura380ampl-1] + $fura380amplwave[preffura380ampl] + $fura380amplwave[preffura380ampl+1])/3
		//fura380data = ($fura380amplwave[preffura380ampl-1]+$fura380amplwave[preffura380ampl]+$fura380amplwave[preffura380ampl+1])/3
			deltafura380 = (fura380fit - fura380data)/BeadUnits					//Converts Delta380 to BUs
			timeofdeltafura380=$fura380timewave[preffura380ampl]
			
	//Determining current integral
		currentintegral = abs(area($analysiswave,endleak,timeofdeltafura380))		//units (pC)

	//Determining Pf value
		fvalue = deltafura380/currentintegral										//calculates f & Pf
		Pf=100*fvalue/FMax

//**Displaying current integral
		Duplicate/O/R=(endleak,timeofdeltafura380) $analysiswave $currentintegralwave
		AppendToGraph/L $currentintegralwave
			ModifyGraph mode($currentintegralwave)=4,marker($currentintegralwave)=0,mskip($currentintegralwave)=100
			ModifyGraph mode($currentintegralwave)=7,hbFill($currentintegralwave)=5

	ReorderTraces $fura380amplwave,{$analysiswave,$displayfura380fit,$currentintegralwave}

//Adding values to graph		

		Textbox /F=0/A=LB/X=40/Y=30 	"current wave: " + analysiswave
			AppendText "Leak current = " + num2str(round(leakcurrent*10)/10) + " pA"
			AppendText "peak current = " + num2str(round(peakcurrent*10)/10) + " pA"
			AppendText "CurrentIntegral = " + num2str(round(currentintegral*10)/10) + " pQ" 
			AppendText "DeltaF380 = " + num2str(round(deltafura380*10)/10) + " BU"
			AppendText "Pf = " + num2str(round(Pf*10)/10) + "%"
	
			AppendText "fmax (BU/pC): "+num2str(fmax)+"; BU (mV): "+num2str(BeadUnits)

	
End Macro()



//***********************************************************************
//
//Deriving charge integrals from QVs and Mg2+ block
//
//***********************************************************************
//***This program is not included in Main Menu


Macro ChargeIntegral(QVslope,Delta,K_0,Blockerconc)
	Variable QVslope = 9.65
		prompt QVslope, "QV Slope"
	Variable Delta
		prompt Delta, "delta"
	Variable K_0
		prompt K_0, "K0.5(0mV) in mM"
	Variable BlockerConc = 1
		prompt BlockerConc, "Extracellular blocker concentration (mM)"
	
	Silent 1

	Variable RT_F = 25.4
	Variable charge = 2
	Variable currentintegral

	Make/O/N=1000 QVcurve
		SetScale/I x -100,40,"", QVcurve
	Make/O/N=1000 Voltage
		SetScale/I x -100,40,"", Voltage
	
	QVcurve = QVSlope*x + 0					//Assume intercept is 0

	
//Generating Mg block

	
	Duplicate/O QVCurve QVCurveBlock
	
//	QVCurveBlock = QVCurveBlock/(1 + BlockerConc * exp(-(charge*Delta*x)/RT_F)*1/K_0)
	QVCurveBlock = QVCurve/(1 + (BlockerConc/(K_0 * exp(charge*Delta*x/RT_F))))
	
	Display QVCurve
		Append QVCurveBlock
		
		ModifyGraph zero=1,standoff=0
		ModifyGraph rgb(QVcurve)=(0,0,0)


//Determining current integral

	currentintegral = abs(area(QVCurveBlock,-100, 0))			//units (pC)
	
	Textbox /F=0/A=LB/X=40/Y=30 	"Current integral: " + num2str(currentintegral)

	
	
End Macro()