libname epproj "C:\Users\HP\OneDrive\Desktop\EP 850\";

data proj1;
	set epproj.nsch_2021_topical;
	/*restricted dataset to 0-5 year olds*/
	where FORMTYPE = 'T1';
	/*applying exclusion criteria*/
	/*exculsion criteria was those who have never breastfed and those who have had a history of chronic illness
	affecting oral health like cerebral palsy, autism and developmental delay*/
	if K6Q40 =2 then delete;
	if K2Q61A =1 then delete;
	if K2Q61B =1 or K2Q61B= 2 then delete;
	if K2Q36A=1 then delete;
	if K2Q36B =1 or K2Q36B=2 then delete;
	if K2Q35A=1 then delete;
	if K2Q35B =1 or K2Q35B=2 then delete;

	/*setting coded missing values to missing*/
	if BREASTFEDEND_DAY_S in (.M,.L,.N,.D) then BREASTFEDEND_DAY_S = .;
	if BREASTFEDEND_MO_S in (.M,.L,.N,.D) then BREASTFEDEND_MO_S=.;
	if BREASTFEDEND_WK_S in (.M,.L,.N,.D) then BREASTFEDEND_WK_S=.;
	
	/*Convert weeks and days at which breastfeeding was stopped to months*/
	BREASTFEDSTOP_DAYMONTHS = BREASTFEDEND_DAY_S/30;
	BREASTFEDSTOP_WKSMONTHS = BREASTFEDEND_WK_S/4;
	
	/*operationalizing the variable, BREASTFEDSTOP_NEW*/
	if BREASTFEDSTOP_DAYMONTHS=. and BREASTFEDSTOP_WKSMONTHS=. and BREASTFEDEND_MO_S=. then BREASTFEDSTOP_NEW=.;
	else if BREASTFEDSTOP_DAYMONTHS=. and BREASTFEDSTOP_WKSMONTHS=. and BREASTFEDEND_MO_S ^=. then BREASTFEDSTOP_NEW= BREASTFEDEND_MO_S;
	else if BREASTFEDSTOP_DAYMONTHS =. and BREASTFEDSTOP_WKSMONTHS ^=. and BREASTFEDEND_MO_S ^=. then BREASTFEDSTOP_NEW= BREASTFEDEND_MO_S + BREASTFEDSTOP_WKSMONTHS;
	else if BREASTFEDSTOP_DAYMONTHS ^=.  and BREASTFEDEND_MO_S ^=. then BREASTFEDSTOP_NEW= BREASTFEDEND_MO_S + BREASTFEDSTOP_DAYMONTHS;
	label BREASTFEDSTOP_NEW="Age in months breastfeeding was stopped";

	/*operationalizing the variable, BREASTFED_DUR*/
	if K6Q41R_STILL=. and BREASTFEDSTOP_NEW=. then do;
    BREASTFED_DUR=.;
	end;
	else if K6Q41R_STILL = 2 and BREASTFEDSTOP_NEW <12 then do;
    BREASTFED_DUR=1;
	end;
	else if K6Q41R_STILL = 2 and BREASTFEDSTOP_NEW >=12 then do;
    BREASTFED_DUR=2;
	end;
	label BREASTFED_DUR="Breastfeeding duration at cessation";

	if CAVITIES in (.L,.M,.N,.D) then CAVITIES_new = .;
	else if CAVITIES = 2 then CAVITIES_new = 0;
	else CAVITIES_new = 1;
	label CAVITIES_new="Difficulty Cavities Past 12 months (recoded)";
	
	if MOMAGE in (.L,.M,.N,.D) then MOMAGE_new=.;
	else if MOMAGE <=30 then MOMAGE_new = 1;
	else MOMAGE_new = 2;
	label MOMAGE_new = "Maternal age categorized";

	if K9Q40 in (.L,.M,.N,.D) then K9Q40_new=.;
	else if K9Q40 = 2 then K9Q40_new = 0;
	else K9Q40_new = 1;
	label K9Q40_new=" If anyone uses cigarette in household recoded";

	if FAMILY_R in (.M,.L,.N,.D) then FAMILY_R =.;

	if ACE1 in (.M,.L,.N.,.D) then ACE1=.;
	if HIGRADE_TVIS in (.M,.L,.N.,.D) then HIGRADE_TVIS=.;
	if SC_RACE_R in (.M,.L,.N.,.D) then SC_RACE_R=.;
	if CURRCOV in (.M,.L,.N.,.D) then CURRCOV=.;

run;
/*QCing my newly created varibales and checking for consistency with ones already in dataset*/
proc freq data=proj1;
	tables BREASTFEDSTOP_NEW;
run;

proc print data=proj1;
	var BREASTFEDEND_DAY_S BREASTFEDEND_MO_S BREASTFEDEND_WK_S BREASTFEDSTOP_DAYMONTHS BREASTFEDSTOP_WKSMONTHS BREASTFEDSTOP_NEW;
run;
proc freq data=proj1;
	tables K6Q41R_STILL;
run;

proc freq data=proj1;
	tables BREASTFED_DUR;
run;
proc freq data=proj1;
	tables MOMAGE;
run;
proc freq data=proj1;
	tables MOMAGE_new;
run;

proc freq data=proj1;
	tables K9Q40 K9Q40_new;
run;

proc freq data=proj1;
	tables BREASTFED_DUR * CAVITIES_new/nocol nocum nopercent;
run;
/*Constructing Table 1*/
proc freq data=proj1;
	tables BREASTFED_DUR * SC_AGE_YEARS/nocol nopercent norow nocum;
run;
proc means data=proj1;
	var  SC_AGE_YEARS;
	where BREASTFED_DUR=1 ;
run;

proc means data=proj1;
	var SC_AGE_YEARS;
	where BREASTFED_DUR=2;
run;

proc means data=proj1 nmiss;
	var  MOMAGE;
	where BREASTFED_DUR=1 ;
run;

proc means data=proj1 nmiss;
	var MOMAGE;
	where BREASTFED_DUR=2;
run;


proc freq data=proj1;
	tables BREASTFED_DUR * SC_SEX/nocol nocum nopercent;
run;
proc freq data=proj1;
	tables BREASTFED_DUR * SC_RACE_R/nocol nocum nopercent;
run;

proc freq data=proj1;
	tables BREASTFED_DUR*HIGRADE_TVIS/nocol nopercent nocum;
run;
proc freq data=proj1;
	tables BREASTFED_DUR*FAMILY_R/nocol nopercent nocum;
run;

proc freq data=proj1;
	tables BREASTFED_DUR*CURRCOV/nocol nopercent nocum;
run;

/*Confounder assessment - complete case analysis*/
/*Remove subjects with missing data on any covariates of interest for estimation of crude*/
data proj1cca;
	set proj1;
	if ACE1=. then delete;
	if HIGRADE_TVIS=. then delete;
	if SC_RACE_R=. then delete;
run;

proc freq data=proj1cca;
	tables SC_RACE_R K9Q40_new ACE1 HIGRADE_TVIS FAMILY_R/missing;
run;

proc logistic data=proj1cca desc;
	class BREASTFED_DUR (param=ref ref='1');
	model CAVITIES_new=BREASTFED_DUR;
run;

%macro logistic(var);
  proc logistic data=proj1cca desc;
    class BREASTFED_DUR (param=ref ref='1') &var;
    model CAVITIES_new = BREASTFED_DUR &var;
  run;
%mend;

*categorical variables*;
%logistic (ACE1);
%logistic (HIGRADE_TVIS);
%logistic (SC_RACE_R);

%macro logistic (var);
proc logistic data=proj1cca desc;
	class BREASTFED_DUR (param=ref ref='1') &var;
	model CAVITIES_new = BREASTFED_DUR SC_RACE_R &var;
run;
%mend;

*categorical variables*;
%logistic (ACE1);
%logistic (HIGRADE_TVIS);


%macro logistic (var);
proc logistic data=proj1cca desc;
	class BREASTFED_DUR (param=ref ref='1') &var;
	model CAVITIES_new = BREASTFED_DUR  SC_RACE_R HIGRADE_TVIS &var;
run;
%mend;

*categorical variables*;
%logistic (ACE1);



/*Looking at EMM of the CAVITIES_new - BREASTFED_DUR by CURRCOV (Insurance coverage)*/
proc freq data=proj1;
	tables CAVITIES_new BREASTFED_DUR CURRCOV/missing;
run;

proc freq data=proj1;
	tables CAVITIES_new * BREASTFED_DUR/cmh;
	where CURRCOV=1;
run;

proc freq data=proj1;
	tables CAVITIES_new * BREASTFED_DUR/cmh;
	where CURRCOV=2;
run;
