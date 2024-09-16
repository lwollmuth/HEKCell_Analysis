# HEKCell_Analysis

Programs for Analysis of Whole-cell and Outside-out patches. Most recordings are from HEK293 Cells though we have also used routines for patches from brain slices.
Note that this code is in many ways not very sophisticated or user friendly. The algorithms used for analysis are often cumbersome and were written over an extended time.
If one wants to use, please verify rigorously the output - that it is capturing properly the data and analysis.

Code was written in Igor Pro 7. Sorry need to upgrade Igor version
Earlier routines used 'Macros' whereas newer rountines use 'Functions'.

Most routines are designed to integrate with HEKA Patchmaster. Hence, assumed file name format is: GroupNo_SeriesNo_SweepNo. 
A strength of these routines is batch processing of records, assuming this file name format.
To load files from HEKA PatchMaster requires "bpc_ReadHeka' (included in files). This also only works with 32 byte version.
