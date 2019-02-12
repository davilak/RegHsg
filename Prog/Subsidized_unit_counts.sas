/**************************************************************************
 Program:  Subsidized_units_counts.sas
 Library:  RegHsg
 Project:  NeighborhoodInfo DC
 Author:   W. Oliver
 Created:  02/7/19
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
download for whole metro area or states if easier. We would like to be able to understand where properties are located, how many units are subsidized (at what level if known), subsidy programs involved, and any expiration dates for the subsidies.

We want all jurisdictions in the COG region:

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
%DCData_lib( RegHsg, local=n )
*Create property and unit counts for individual programs**;

proc format;
	value COG
    1= "COG county"
    0="Non COG county";

run;
proc format;
	value ActiveUnits
    1= "Active subsidies"
    0="No active subsidies";
	run;
proc format;
	value ProgCat
	1= "Public housing"
	2= "Public housing and other subsidies"
	3= "Section 8 only"
	4= "Section 8 and HUD mortgage (FHA or S236) only"
	5= "Section 8 and other subsidy combinations"
	6= "LIHTC only"
	7= "LIHTC and other subsidies"
	8= "HOME only"
	9= "RHS only"
	10= "S202/811 only"
	11= "HUD insured mortgage only"
	12= "All other subsidy combinations";

run;

data Work.Allassistedunits;
	set RegHsg.Natlpres_activeandinc_prop;
	if CountyCode in ("11001", "24017", "24021", "24031", "24033", "51013", "51059", "51107", "51153", "51510", "51600", "51610", "51683", "51685") then COGregion =1;
  	else COGregion=0;
  	format COGregion COG. ;
	s8_all_assistedunits=min(sum(s8_1_AssistedUnits, s8_2_AssistedUnits,0),TotalUnits);
	s202_all_assistedunits=min(sum(s202_1_AssistedUnits, s202_2_AssistedUnits,0),TotalUnits);
	s236_all_assistedunits=min(sum(s236_1_AssistedUnits, s236_2_AssistedUnits,0),TotalUnits);
	FHA_all_assistedunits=min(sum(FHA_1_AssistedUnits, FHA_2_AssistedUnits,0),TotalUnits);
	LIHTC_all_assistedunits=min(sum(LIHTC_1_AssistedUnits,LIHTC_2_AssistedUnits,0),TotalUnits);
	rhs515_all_assistedunits=min(sum(RHS515_1_AssistedUnits,RHS515_2_AssistedUnits,0),TotalUnits);
	rhs538_all_assistedunits=min(sum(RHS538_1_AssistedUnits,RHS538_2_AssistedUnits,0),TotalUnits);
	HOME_all_assistedunits=min(sum(HOME_1_AssistedUnits, HOME_2_AssistedUnits,0),TotalUnits);
	PH_all_assistedunits=min(sum(PH_1_AssistedUnits, PH_2_AssistedUnits,0),TotalUnits);
	State_all_assistedunits=min(sum(State_1_AssistedUnits, State_2_AssistedUnits,0),TotalUnits);
	drop s8_1_AssistedUnits s8_2_AssistedUnits s202_1_assistedunits s202_2_assistedunits
	s236_1_AssistedUnits s236_2_AssistedUnits FHA_1_AssistedUnits FHA_2_AssistedUnits
	LIHTC_1_AssistedUnits LIHTC_2_AssistedUnits RHS515_1_AssistedUnits RHS515_2_AssistedUnits
	RHS538_1_AssistedUnits RHS538_2_AssistedUnits HOME_1_AssistedUnits HOME_2_AssistedUnits
	PH_1_AssistedUnits PH_2_AssistedUnits State_1_AssistedUnits State_2_AssistedUnits;

	if s8_all_assistedunits > 0 
	then s8_activeunits = 1;
	else s8_activeunits = 0;
	
	if s202_all_assistedunits > 0
	then s202_activeunits = 1;
	else s202_activeunits = 0;

	if s236_all_assistedunits > 0
	then s236_activeunits = 1;
	else s236_activeunits = 0;

	if FHA_all_assistedunits > 0
	then FHA_activeunits = 1;
	else FHA_activeunits = 0;

	if LIHTC_all_assistedunits > 0
	then LIHTC_activeunits = 1;
	else LIHTC_activeunits = 0;

	if rhs515_all_assistedunits > 0
	then rhs515_activeunits = 1;
	else rhs515_activeunits = 0;

	if rhs538_all_assistedunits > 0
	then rhs538_activeunits = 1;
	else rhs538_activeunits = 0;

	if HOME_all_assistedunits > 0
	then HOME_activeunits = 1;
	else HOME_activeunits = 0;

	if PH_all_assistedunits > 0
	then PH_activeunits = 1;
	else PH_activeunits = 0;

	if State_all_assistedunits > 0
	then State_activeunits = 1;
	else State_activeunits = 0;

	format State_activeunits PH_activeunits HOME_activeunits rhs538_activeunits rhs515_activeunits
	LIHTC_activeunits FHA_activeunits s236_activeunits s202_activeunits s8_activeunits ActiveUnits.;
run;

** Check assisted unit counts and flags **;

proc means data=Work.Allassistedunits n sum mean min max;
run;


data Work.SubsidyCategories;
	set Work.Allassistedunits;

	if PH_activeunits  and not( fha_activeunits or home_activeunits or 
	lihtc_activeunits or rhs515_activeunits or rhs538_activeunits or 
	s202_activeunits or s236_activeunits ) 
	then ProgCat = 1;

	else if PH_activeunits then ProgCat = 2;

	else if s8_activeunits and not( fha_activeunits or home_activeunits or 
	lihtc_activeunits or rhs515_activeunits or rhs538_activeunits or 
	s202_activeunits or s236_activeunits ) 
	then ProgCat = 3;

	else if s8_activeunits and ( fha_activeunits or s236_activeunits ) and 
	not( home_activeunits or lihtc_activeunits or rhs515_activeunits or 
	rhs538_activeunits or s202_activeunits ) 
	then ProgCat = 4;

	else if s8_activeunits then ProgCat = 5;

	else if lihtc_activeunits and not( fha_activeunits or home_activeunits or 
	rhs515_activeunits or rhs538_activeunits or s202_activeunits or 
	s236_activeunits ) 
	then ProgCat = 6;

	else if lihtc_activeunits then ProgCat = 7;

	else if home_activeunits and not ( fha_activeunits or s8_activeunits or 
	rhs515_activeunits or rhs538_activeunits or s202_activeunits or 
	s236_activeunits ) 
	then ProgCat = 8;

	
   	else if (rhs515_activeunits or rhs538_activeunits) and not (fha_activeunits or s8_activeunits or 
	home_activeunits or s202_activeunits or s236_activeunits ) 
	then ProgCat = 9;

	else if s202_activeunits and not( fha_activeunits or s8_activeunits or 
	rhs515_activeunits or rhs538_activeunits or home_activeunits or 
	s236_activeunits ) 
	then ProgCat=10;

	else if (fha_activeunits or s236_activeunits) and not (home_activeunits or lihtc_activeunits or rhs515_activeunits or 
	rhs538_activeunits or s202_activeunits or s8_activeunits)
	then ProgCat=11;

	else ProgCat =12;


	format ProgCat ProgCat.;

	run;

** Check project category coding **;

proc sort data=Work.SubsidyCategories;
  by ProgCat;
run;

proc freq data=Work.SubsidyCategories;
  by ProgCat;
  tables ph_activeunits * s8_activeunits * lihtc_activeunits * 
    home_activeunits * rhs515_activeunits * s202_activeunits * s236_activeunits * fha_activeunits 
    / list missing nocum nopercent;
  format 
    ProgCat ProgCat. 
    ph_activeunits s8_activeunits lihtc_activeunits home_activeunits 
    rhs515_activeunits s202_activeunits s236_activeunits fha_activeunits ;
run;


data Work.SubsidyExpirationDates;

  set Work.SubsidyCategories;

  min_assistedunits = max( s8_all_assistedunits, s202_all_assistedunits, s236_all_assistedunits,FHA_all_assistedunits,
	LIHTC_all_assistedunits,rhs515_all_assistedunits,rhs538_all_assistedunits,HOME_all_assistedunits ,PH_all_assistedunits,0);
	max_assistedunits = min( sum( s8_all_assistedunits, s202_all_assistedunits,s236_all_assistedunits,FHA_all_assistedunits,
	LIHTC_all_assistedunits,rhs515_all_assistedunits,rhs538_all_assistedunits,HOME_all_assistedunits ,PH_all_assistedunits,0 ), TotalUnits );
	mid_assistedunits = min( round( mean( min_assistedunits, max_assistedunits ), 1 ), max_assistedunits );

  if mid_assistedunits ~= max_assistedunits then moe_assistedunits = max_assistedunits - mid_assistedunits;

  earliest_expirationdate = min(S8_1_EndDate,LIHTC_1_EndDate,S8_2_EndDate,S202_1_EndDate,S202_2_EndDate,S236_1_EndDate,S236_2_EndDate,
	LIHTC_2_EndDate,RHS515_1_EndDate,RHS515_2_EndDate,RHS538_1_EndDate,RHS538_2_EndDate,HOME_1_EndDate,HOME_2_EndDate,
	FHA_1_EndDate,FHA_2_EndDate,PH_1_EndDate,PH_2_EndDate);

  latest_expirationdate = max(S8_1_EndDate,LIHTC_1_EndDate,S8_2_EndDate,S202_1_EndDate,S202_2_EndDate,S236_1_EndDate,S236_2_EndDate,
	LIHTC_2_EndDate,RHS515_1_EndDate,RHS515_2_EndDate,RHS538_1_EndDate,RHS538_2_EndDate,HOME_1_EndDate,HOME_2_EndDate,
	FHA_1_EndDate,FHA_2_EndDate,PH_1_EndDate,PH_2_EndDate);

	format latest_expirationdate MMDDYY10.;
	format earliest_expirationdate MMDDYY10.;

label
  min_assistedunits = 'Minimum possible assisted units in project'
  max_assistedunits = 'Maximum possible assisted units in project'
  mid_assistedunits = 'Midpoint of project assisted unit estimate in project'
  moe_assistedunits = 'Margin of error for assisted unit estimate in project'
  earliest_expirationdate = 'Earliest expiration date for property'
  latest_expirationdate= 'Latest expiration date for property';


  run;

** Review results of assisted unit and expiration date calculations **;

proc sort data=Work.SubsidyExpirationDates;
  by ProgCat;
run;

proc means data=Work.SubsidyExpirationDates n mean min max;
  by ProgCat;
  var min_assistedunits max_assistedunits mid_assistedunits moe_assistedunits 
      earliest_expirationdate latest_expirationdate;
  format ProgCat ProgCat.;
run;

