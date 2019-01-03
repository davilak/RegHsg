/**************************************************************************
 Program:  Vulnerable to gentrification_Jurisdiction.sas
 Library:  RegHsg
 Project:  NeighborhoodInfo DC
 Author:   Yipeng Su 
 Created:  12/19/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Calculate risk of gentrification and displacement for the COGS region: methodology by https://www.portlandoregon.gov/bps/article/454027
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

change in characteristics that make resisting displacement more difficult(binary): % renters, %people of color, %college attainment, %lower income

change in characteristics that reflect gentrification (low median high): median home value relative to citywide median, appreciation rates for owner-occupoed units

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( RegHsg)
%DCData_lib( ACS)
%DCData_lib( Census)
%DCData_lib( NCDB)
%DCData_lib( Ipums)

%let _years=2012_16;

** Calculate average ratio of gross rent to contract rent for occupied units **;
data demographics16 (where=(county in ("11001", "24017", "24021", "24031", "24033", "51013", "51059", "51107", "51153", "51510", "51600","51610", "51683", "51685" )));
set ACS.Acs_2012_16_dc_sum_tr_tr10 ACS.Acs_2012_16_md_sum_tr_tr10 ACS.Acs_2012_16_va_sum_tr_tr10 ACS.Acs_2012_16_wv_sum_tr_tr10;
keep geo2010 county Jurisdiction percentrenter_2016 percentwhite_2016 percentcollege_2016 avghhinc_2016 popwhitenonhispbridge_&_years. popwithrace_&_years. numrenteroccupiedhu_&_years. numowneroccupiedhu_&_years. pop25andoverwcollege_&_years. pop25andoveryears_&_years. agghshldincome_&_years.  numhshlds_&_years. medianhomevalue_&_years. ;
county= substr(geo2010,1,5);
percentrenter_2016= numrenteroccupiedhu_&_years./(numrenteroccupiedhu_&_years.+numowneroccupiedhu_&_years.);
percentwhite_2016= popwhitenonhispbridge_&_years./popwithrace_&_years.;
percentcollege_2016= pop25andoverwcollege_&_years./pop25andoveryears_&_years.;
avghhinc_2016= agghshldincome_&_years./(numhshlds_&_years. );
if county in ("11001") then Jurisdiction=1;
if county in ("24017") then Jurisdiction=2;
if county in ("24021") then Jurisdiction=3;
if county in ("24031") then Jurisdiction=4;
if county in ("24033") then Jurisdiction=5;
if county in ("51013") then Jurisdiction=6;
if county in ("51600", "51059","51610") then Jurisdiction=7;
if county in ("51107") then Jurisdiction=8;
if county in ("51153", "51683","51685") then Jurisdiction=9;
if county in ("51510") then Jurisdiction=10;
run;

proc sort data=demographics16;
by geo2010;
run;

data demographics00(where=(county in ("11001", "24017", "24021", "24031", "24033", "51013", "51059", "51107", "51153", "51510", "51600","51610", "51683", "51685" )));
set NCDB.Ncdb_master_update;
keep geo2010 county Jurisdiction percentrenter_00 percentwhite_00 percentcollege_00 avghhinc_00 sprntoc0 spownoc0 shr0d minwht0n educpp0 educ160 avhhin0 avghhinc_00a numhhs0;
county= substr(geo2010,1,5);
percentrenter_00= sprntoc0/(sprntoc0+spownoc0);
percentwhite_00= minwht0n/shr0d;
percentcollege_00= educ160/educpp0;
avghhinc_00= avhhin0;

%dollar_convert( avghhinc_00, avghhinc_00a, 1999, 2016, series=CUUR0000SA0 )

run;

proc sort data=demographics00;
by geo2010;
run;

data merged;
merge demographics16 demographics00;
by geo2010;
COG=1;
run;

data changeintime;
set merged;
deltarenter = numrenteroccupiedhu_&_years./(numrenteroccupiedhu_&_years.+numowneroccupiedhu_&_years.)- sprntoc0/(sprntoc0+spownoc0);
deltawhite= percentwhite_2016- percentwhite_00;
deltacollege= percentcollege_2016- percentcollege_00;
deltahhinc= (avghhinc_2016-avghhinc_00a)/avghhinc_00a;
run;

proc means data=changeintime median;
run;

proc summary data= changeintime;
class COG Jurisdiction;
var numrenteroccupiedhu_&_years. numowneroccupiedhu_&_years. popwhitenonhispbridge_&_years. popwithrace_&_years. pop25andoverwcollege_&_years. pop25andoveryears_&_years. agghshldincome_&_years. numhshlds_&_years. avghhinc_00a sprntoc0 spownoc0 minwht0n shr0d educ160 educpp0 numhhs0;
output out = vulnerable_2016  sum=;
run;

/*calculate vulnerability threshold based on region total*/
data vulnerablethreshold;
set vulnerable_2016(where=(COG = 1));
keep geo2010 county Jurisdiction percentrenter_2016 percentwhite_2016 percentcollege_2016 avghhinc_2016 popwhitenonhispbridge_&_years. popwithrace_&_years. numrenteroccupiedhu_&_years. numowneroccupiedhu_&_years. pop25andoverwcollege_&_years. pop25andoveryears_&_years. agghshldincome_&_years.  numhshlds_&_years. medianhomevalue_&_years. ;
county= substr(geo2010,1,5);
percentrenter_2016= numrenteroccupiedhu_&_years./(numrenteroccupiedhu_&_years.+numowneroccupiedhu_&_years.);
percentwhite_2016= popwhitenonhispbridge_&_years./popwithrace_&_years.;
percentcollege_2016= pop25andoverwcollege_&_years./pop25andoveryears_&_years.;
avghhinc_2016= agghshldincome_&_years./(numhshlds_&_years. );
run;

proc summary data= changeintime;
class COG Jurisdiction;
var numrenteroccupiedhu_&_years. numowneroccupiedhu_&_years. popwhitenonhispbridge_&_years. popwithrace_&_years. pop25andoverwcollege_&_years. pop25andoveryears_&_years. agghshldincome_&_years. numhshlds_&_years. avghhinc_00a sprntoc0 spownoc0 minwht0n shr0d educ160 educpp0 numhhs0;
output out = demographicschange_2016  sum=;
run;


data demographic_threshold;
set demographicschange_2016 (where=(COG=1));
deltarenter = numrenteroccupiedhu_&_years./(numrenteroccupiedhu_&_years. +numowneroccupiedhu_&_years.)- sprntoc0/(sprntoc0+spownoc0);
deltawhite= popwhitenonhispbridge_&_years./popwithrace_&_years.- minwht0n/shr0d;
deltacollege= pop25andoverwcollege_&_years./pop25andoveryears_&_years. - educ160/educpp0;
deltahhinc= ((agghshldincome_&_years. /numhshlds_&_years.)-avghhinc_00a)/avghhinc_00a;
run;

%macro risk_jurisdiction(juris);

%let vars = 1 2 3 4 5 6 7 8 9 10;
%let nv = %sysfunc(countw(&vars.));

%do i = 1 %to &nv.;
%let juris = %scan(&vars.,&i.," ");

proc sql noprint;
select percentrenter_2016 
into :renterthresh separated by " "
from vulnerablethreshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select deltarenter 
into :renterthresh_d separated by " "
from demographic_threshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select percentwhite_2016 
into :whitethresh separated by " "
from vulnerablethreshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select deltawhite
into :whitethresh_d separated by " "
from demographic_threshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select percentcollege_2016 
into :collegethresh separated by " "
from vulnerablethreshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select deltacollege 
into :collegethresh_d separated by " "
from demographic_threshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select avghhinc_2016 
into :hhincthresh separated by " "
from vulnerablethreshold (where = (Jurisdiction = &juris.));
quit;

proc sql noprint;
select deltahhinc
into :hhincthresh_d separated by " "
from demographic_threshold (where = (Jurisdiction = &juris.));
quit;

%put &renterthresh. &whitethresh. &collegethresh. &hhincthresh. &renterthresh_d. &whitethresh_d. &collegethresh_d. &hhincthresh_d.;

/* identify tracts with higher than average population with characteristics that make resisting displacement more difficult:
renters, POC, lack college degree, lower income*/
/*median for 2016: percentwhite:0.437 percentrenter: 0.383 percentcollege 0.514 averageincome 123451.1*/

data risk_displacement (where=(Jurisdiction=&juris.));
set changeintime;
		if percentrenter_2016 >= &renterthresh. then vulnerable_renter =1;
	    else if percentrenter_2016< &renterthresh. then vulnerable_renter =0;
		else if percentrenter_2016=. then vulnerable_renter =.;

if percentwhite_2016<= &whitethresh. then vulnerable_POC=1;
else if percentwhite_2016> &whitethresh. then vulnerable_POC=0;
else if percentwhite_2016=. then vulnerable_POC=.;

if percentcollege_2016<= &collegethresh. then vulnerable_college=1;
else if percentcollege_2016 > &collegethresh. then vulnerable_college=0;
else if percentcollege_2016=. then vulnerable_college=.;

if avghhinc_2016 <= &hhincthresh. then vulnerable_inc=1;
else if avghhinc_2016> &hhincthresh. then vulnerable_inc=0;
else if avghhinc_2016=. then vulnerable_inc=.;

vulnerablesum= vulnerable_renter + vulnerable_POC + vulnerable_college + vulnerable_inc;

if vulnerablesum>=3 then vulnerable=1; else vulnerable=0;

run;

/* identify change of tract demographics that are signalling gentrification:
change in renters, more white people, more college degree, higher income*/
/*means for deltarenter:-0.026516813   deltawhite: -0.13102085 deltacollege: 0.0725301253 deltainc: -0.999144121*/

/*calculate demographic change threshold based on region total*/

data risk_gentrification;
set risk_displacement;
		if deltarenter <= &renterthresh_d. then gentrifier_owner =1;
	    else if deltarenter> &renterthresh_d. then vulnerable_renter =0;
		else if deltarenter=. then vulnerable_renter =.;

if deltawhite>= &whitethresh_d. then gentrifier_white=1;
else if deltawhite< &whitethresh_d. then gentrifier_white=0;
else if deltawhite=. then gentrifier_white=.;

if deltacollege>= &collegethresh_d. then gentrifier_college=1;
else if deltacollege < &collegethresh_d. then gentrifier_college=0;
else if deltacollege=. then gentrifier_college=.;

if deltahhinc >= &hhincthresh_d. then gentrifier_inc=1;
else if deltahhinc < &hhincthresh_d. then gentrifier_inc=0;
else if deltahhinc=. then gentrifier_inc=.;

gentrifier= gentrifier_owner + gentrifier_white + gentrifier_college + gentrifier_inc;

if gentrifier>=3 then demographicchange=1; else demographicchange=0;
if gentrifier_white=1 & gentrifier_college=1 then demographicchange=1;

run;

proc format;
  value signofrisk
   .n = 'No complete data'
    1 = 'Yes'
    0 = 'No'
run;

/*signofrisk: 1: gentrifying and vulnerable now 2: gentrifying but not vulnerable now 3; not gentrified but vulnerable 3: not gentrified and not vulnerable*/
data flag_population;
set risk_gentrification;
keep geo2010 county Jurisdiction vulnerable demographicchange percentrenter_2016 percentwhite_2016 percentcollege_2016 avghhinc_2016 popwhitenonhispbridge_&_years. popwithrace_&_years. numrenteroccupiedhu_&_years. numowneroccupiedhu_&_years. pop25andoverwcollege_&_years. pop25andoveryears_&_years. agghshldincome_&_years.  numhshlds_&_years. medianhomevalue_&_years. ;
format vulnerable demographicchange signofrisk. ;
run;


/*Calculate appreciation of home values and rank baseline median home values*/

data housing1990(where=(county in ("11001", "24017", "24021", "24031", "24033", "51013", "51059", "51107", "51153", "51510", "51600","51610", "51683", "51685" )));
set NCDB.Ncdb_master_update;
keep geo2010 county Jurisdiction mdvalhs9 mdvalhs0 mdvalhs0_a mdvalhs9_a;
county= substr(geo2010,1,5);
%dollar_convert( mdvalhs0, mdvalhs0_a, 1999, 2016, series=CUUR0000SA0L2 )
%dollar_convert( mdvalhs9, mdvalhs9_a, 1989, 2016, series=CUUR0000SA0L2 )
if county in ("11001") then Jurisdiction=1;
if county in ("24017") then Jurisdiction=2;
if county in ("24021") then Jurisdiction=3;
if county in ("24031") then Jurisdiction=4;
if county in ("24033") then Jurisdiction=5;
if county in ("51013") then Jurisdiction=6;
if county in ("51600", "51059","51610") then Jurisdiction=7;
if county in ("51107") then Jurisdiction=8;
if county in ("51153", "51683","51685") then Jurisdiction=9;
if county in ("51510") then Jurisdiction=10;
run;

data housingmarket (where=(Jurisdiction=&juris.));
merge merged housing1990;
keep geo2010 geoid county Jurisdiction mdvalhs9_a mdvalhs0_a medianhomevalue_2012_16 appre90_16 appre00_16;
by geo2010;
appre90_16 = (medianhomevalue_2012_16- mdvalhs9_a)/ mdvalhs9_a;
appre00_16 = (medianhomevalue_2012_16-mdvalhs0_a)/mdvalhs0_a;
geoid=geo2010;
run;

proc rank data=housingmarket out=valuehousing groups=5;
 var mdvalhs9_a mdvalhs0_a medianhomevalue_2012_16 appre90_16 appre00_16;
 ranks rank90 rank2000 rank2016 rank90_16 rank00_16 ;
run;

data appreciationtracts;
set valuehousing;

if rank90 <= 2 &  rank2016 >=3 & rank90_16 >= 3 then appreciated =1;else appreciated =0;
if rank2016<=2 & rank00_16 >=3 then accelerating=1;else accelerating=0;

run;

proc freq data=appreciationtracts;
run;

proc export data = appreciationtracts
   outfile="&_dcdata_default_path\RegHsg\Prog\Housing market condition_&juris..csv"
   dbms=csv
   replace;
run;


data completetypology_&juris.;
merge flag_population appreciationtracts;
by geo2010;
run;

proc export data = completetypology
   outfile="&_dcdata_default_path\RegHsg\Prog\completetypology_&juris..csv"
   dbms=csv
   replace;
run;


%end

%mend risk_jurisdiction;

%risk_jurisdiction(1);
%risk_jurisdiction(2);


