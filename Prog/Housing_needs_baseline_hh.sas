/**************************************************************************
 Program:  Housing_needs_baseline.sas
 Library:  RegHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su adapted from P. Tatian 
 Created:  11/03/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Produce numbers for housing needs analysis from 2016
 ACS IPUMS data for the COGS region:
 DC (11001)
 Charles Couty(24017)
 Frederick County(24021)
 Montgomery County (24031)
 Prince George's County(24033)
 Arlington County (51013)
 Fairfax County (51059)
 Loudoun County (51107)
 Prince William County (51153)
 Alexandria City (51510)
 Fairfax City (51600)
 Falls Church City (51610)
 Manassas City (51683)
 Manassas Park City (51685)

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( RegHsg)
%DCData_lib( Ipums)


** Calculate average ratio of gross rent to contract rent for occupied units **;
data COGSvacant(where=(upuma in ("1100101", "1100102", "1100103", "1100104", "1100105", "2401600", "2400301", "2400302","2401001", "2401002", "2401003", "2401004", "2401005", "2401006", "2401007", "2401101", "2401102", "2401103", "2401104", "2401105", "2401106", "2401107", "5101301", "5101302", "5159301", "5159302", "5159303", "5159304", "5159305", "5159306", "5159307", "5159308", "5159309", "5110701", "5110702" , "5110703", "5151244", "5151245", "5151246", "5151255")));
set Ipums.Acs_2012_16_vacant_dc Ipums.Acs_2012_16_vacant_md Ipums.Acs_2012_16_vacant_va ;

  if upuma in ("1100101", "1100102", "1100103", "1100104", "1100105") then Jurisdiction =1;
  if upuma in ("2401600") then Jurisdiction =2;
  if upuma in ("2400301", "2400302") then Jurisdiction =3;
  if upuma in ("2401001", "2401002", "2401003", "2401004", "2401005", "2401006", "2401007") then Jurisdiction =4;
  if upuma in ("2401101", "2401102", "2401103", "2401104", "2401105", "2401106", "2401107") then Jurisdiction =5;
  if upuma in ("5101301", "5101302") then Jurisdiction =6;
  if upuma in ("5159301", "5159302", "5159303", "5159304", "5159305", "5159306", "5159307", "5159308", "5159309") then Jurisdiction =7;
  if upuma in ("5110701", "5110702" , "5110703") then Jurisdiction =8;
  if upuma in ("5151244", "5151245", "5151246") then Jurisdiction =9; 
  if upuma in ("5151255") then Jurisdiction =10; 
run;

data COGSarea (where=(upuma in ("1100101", "1100102", "1100103", "1100104", "1100105", "2401600", "2400301", "2400302","2401001", "2401002", "2401003", "2401004", "2401005", "2401006", "2401007", "2401101", "2401102", "2401103", "2401104", "2401105", "2401106", "2401107", "5101301", "5101302", "5159301", "5159302", "5159303", "5159304", "5159305", "5159306", "5159307", "5159308", "5159309", "5110701", "5110702" , "5110703", "5151244", "5151245", "5151246", "5151255")));
set Ipums.Acs_2012_16_dc Ipums.Acs_2012_16_md Ipums.Acs_2012_16_va;

  if upuma in ("1100101", "1100102", "1100103", "1100104", "1100105") then Jurisdiction =1;
  if upuma in ("2401600") then Jurisdiction =2;
  if upuma in ("2400301", "2400302") then Jurisdiction =3;
  if upuma in ("2401001", "2401002", "2401003", "2401004", "2401005", "2401006", "2401007") then Jurisdiction =4;
  if upuma in ("2401101", "2401102", "2401103", "2401104", "2401105", "2401106", "2401107") then Jurisdiction =5;
  if upuma in ("5101301", "5101302") then Jurisdiction =6;
  if upuma in ("5159301", "5159302", "5159303", "5159304", "5159305", "5159306", "5159307", "5159308", "5159309") then Jurisdiction =7;
  if upuma in ("5110701", "5110702" , "5110703") then Jurisdiction =8;
  if upuma in ("5151244", "5151245", "5151246") then Jurisdiction =9; 
  if upuma in ("5151255") then Jurisdiction =10; 
run;

proc contents data=COGSarea;
run;

data Ratio;

  set COGSarea
    (keep= rent rentgrs pernum gq ownershpd Jurisdiction
     where=(pernum=1 and gq in (1,2) and ownershpd in ( 22 )));
     
  Ratio_rentgrs_rent_12_16 = rentgrs / rent;
 
run;

proc means data=Ratio;
  var  Ratio_rentgrs_rent_12_16 rentgrs rent;
run;

%let Ratio_rentgrs_rent_12_16 = 1.1512114;         %** Value copied from Proc Means output **;

data Housing_needs_baseline;

  set COGSarea
        (keep=year serial pernum hhwt hhincome numprec bedrooms gq ownershp owncost ownershpd rentgrs valueh Jurisdiction
         where=(pernum=1 and gq in (1,2) and ownershpd in ( 12,13,21,22 )));
  
  %Hud_inc_RegHsg( hhinc=hhincome, hhsize=numprec )
  
  label
    hud_inc = 'HUD income category for household';

** Rent burdened flag **;

    if ownershp = 2 then do;
		if rentgrs*12>= HHINCOME*0.3 then rentburdened=1;
	    else if HHIncome~=. then rentburdened=0;
	end;

    if ownershp = 1 then do;
		if owncost*12>= HHINCOME*0.3 then ownerburdened=1;
	    else if HHIncome~=. then ownerburdened=0;
	end;

** Severely rent burdened flag **;

    if ownershp = 2 then do;
		if rentgrs*12>= HHINCOME*0.5 then severerentburden=1;
	    else if HHIncome~=. then severerentburden=0;
	end;

    if ownershp = 1 then do;
		if owncost*12>= HHINCOME*0.5 then severeownerburden=1;
	    else if HHIncome~=. then severeownerburden=0;
	end;


	tothh = 1;

run;

%File_info( data=Housing_needs_baseline, freqvars=hud_inc rentburdened ownerburdened )

proc freq data=Housing_needs_baseline;
  tables ownershpd * ownerburdened * rentburdened ( hud_inc ) / list missing;
  format ownershpd vacancy ;
run;
proc freq data=Housing_needs_baseline;
  tables ownershpd * severeownerburden * severerentburden ( hud_inc ) / list missing;
  format ownershpd vacancy ;
run;

proc format;
  value hud_inc
   .n = 'Vacant'
    1 = '0-30% AMI'
    2 = '31-50%'
    3 = '51-80%'
    4 = '81-120%'
    5 = '120-200%'
    6 = 'More than 200%';
  value tenure
    1 = 'Renter units'
    2 = 'Owner units';
  value Jurisdiction
    1= "DC"
	2= "Charles County"
	3= "Frederick County "
	4="Montgomery County"
	5="Prince Georges "
	6="Arlington"
	7="Fairfax, Fairfax city and Falls Church"
	8="Loudoun"
	9="Prince William, Manassas and Manassas Park"
    10="Alexandria";
run;

proc summary data = Housing_needs_baseline (where=(ownershp = 2));
	class hud_inc Jurisdiction;
	var rentburdened severerentburden tothh;
	weight hhwt;
	output out = Housing_needs_baseline_renter sum=;
	format hud_inc hud_inc. Jurisdiction Jurisdiction.;
run;

proc summary data = Housing_needs_baseline (where=(ownershp = 1));
	class hud_inc Jurisdiction;
	var ownerburdened severeownerburden tothh;
	weight hhwt;
	output out = Housing_needs_baseline_owner  sum=;
	format hud_inc hud_inc. Jurisdiction Jurisdiction.;
run;

proc export data = Housing_needs_baseline_renter
   outfile="&_dcdata_default_path\RegHsg\Prog\Renter_baseline.csv"
   dbms=csv
   replace;
run;

proc export data = Housing_needs_baseline_owner
   outfile="&_dcdata_default_path\RegHsg\Prog\Owner_baseline.csv"
   dbms=csv
   replace;
run;


