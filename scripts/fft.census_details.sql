
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

-- Note: in our own projects, FFT use numeric columns to store several of the
-- character-based codes in the census_details table, for example the ethncity
-- and SEN types columns; these shared scripts use the original character-based
-- codes so that they are easier to use without additional reference tables.
-- An exception to this policy is the LAESTAB_ANON column, which has no inherent
-- meaning and is a particularly bad offender due to its unnecessary code
-- length; this is instead found in the fft.laestab_anon reference table and is
-- used as one of the possible inputs for the institution_id column.

if schema_id('fft') is null
	exec ('create schema fft;');

if object_id('fft.census_details') is null
begin
create table fft.census_details (
	pupil_matching_reference char(18) /* collate Latin1_General_BIN */ not null,
	year smallint not null,
	term_id tinyint not null,
	-- academic_age is the pupil's age at the beginning of the academic year
	academic_age tinyint,
	year_of_birth smallint,
	month_of_birth tinyint,
	gender char(1),
	ethnicity char(4),
	first_language char(3),
	ap_type char(3),
	on_roll bit,
	enrolment_status char(1),
	nc_year char(2),
	entry_date date,
	leaving_date date,
	fsm bit,
	fsm_ever6 bit,
	fsm_ever6p bit,
	sen_status char(1),
	primary_sen_type varchar(4),
	secondary_sen_type varchar(4),
	lsoa_code as country_code + right('0000000'+cast(lsoa_id as varchar(9)), 8),
	idaci_rank int,
	idaci_score real,
	record_status tinyint,
	
	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,
	
	-- The institution_id is a numeric identifier for the insitution (of
	-- whichever type, such as school) in which the individual has been
	-- reported. Since most such institutions are pseudonomised in LEO iteration
	-- 2, the code values themselves are irrelevant so have been replaced with a
	-- more efficient encoding.
	-- LA codes, which appear in AP and PRU censuses are held "as is" and can be
	-- easily identified since they are only 3 digits.
	institution_id int not null,
	
	-- The row_id column is a simple indexer of records that would otherwise
	-- have the same set of values in the primary key columns; it is used to
	-- disambiguate them.
	row_id tinyint not null,
	
	-- The country_code and lsoa_id are a decomposition of the original LSOA
	-- code, which is numeric except for an initial character.
	country_code char(1),
	lsoa_id int,
	
	-- The source_id is the object_id of the source; it can be used for example
	-- in error investigation and resolution to determine where a given record
	-- came from.
	source_id int not null,
	
	-- utilities
	academic_year as cast(year-1 as varchar(16))
		+ '/' + right(cast(year as varchar(16)), 2),
	
	-- These are the original names for fields that FFT has relabelled, allowing
	-- you to use either name (without need to store the data twice).
	PupilMatchingRefAnonymous as pupil_matching_reference,
	YearOfBirth as year_of_birth,
	MonthOfBirth as month_of_birth,
	Sex as gender, -- used in newer versions of census
	EthnicGroupMinor as ethnicity,
	OnRoll as on_roll,
	EnrolStatus as enrolment_status,
	NCYearActual as nc_year,
	EntryDate as entry_date,
	LeavingDate as leaving_date,
	FSMEligible as fsm,
	EverFSM_6 as fsm_ever6,
	EverFSM_6_p as fsm_ever6p,
	SenProvision as sen_status,
	PrimarySENType as primary_sen_type,
	SecondarySENType as secondary_sen_type,
	IdaciRank as idaci_rank,
	IdaciScore as idaci_score,
	RecordStatus as record_status,
	
	primary key (
		fft_person_id,
		year,
		term_id,
		institution_id,
		row_id
		)
	);
alter table fft.census_details rebuild partition = all with (data_compression = page);
end
else truncate table fft.census_details;

-- We could use a temporary table to do this instead, but tempdb has been known
-- to run out of space on the SRS servers when too many users are making use of
-- it concurrently.
if object_id('fft.wip#sc') is null
begin
create table fft.wip#sc (
	pmr varchar(30) collate Latin1_General_BIN not null,
	source_id int not null,
	year smallint not null,
	term_id tinyint not null,
	yob smallint,
	mob tinyint,
	gender char(1),
	ethnicity varchar(50),
	flang varchar(20),
	laestab_anon varchar(30) collate Latin1_General_BIN,
	onroll bit,
	enrol_status char(1),
	ncy char(2),
	entry_date date,
	leaving_date date,
	fsm bit,
	fsm6 bit,
	fsm6p bit,
	sen char(1),
	primary_sen varchar(8),
	secondary_sen varchar(8),
	lsoa varchar(12),
	idaci_rank int,
	idaci_score real,
	record_status tinyint
	);
alter table fft.wip#sc rebuild partition = all with (data_compression = page);
create index ix_pmr on fft.wip#sc (pmr);
end
else truncate table fft.wip#sc;

--------------------------------------------------------------------------------
-- compile sources
--------------------------------------------------------------------------------

if object_id('npd_i2."<project number>".plasc_2003') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_03,
	object_id('npd_i2."<project number>".plasc_2003'),
	2003 year,
	0 term_id,
	yearofbirth_03,
	monthofbirth_03,
	gender_03,
	ethnicgroup_03,
	firstlanguage_03,
	laestab_anon_03,
	null onroll_03,
	enrolstatus_03,
	ncyearactual_03,
	entrydate_03,
	null leavingdate_03,
	fsmeligible_03,
	null everfsm_6_03,
	null everfsm_6_p_03,
	senstatus_03,
	null primarysentype_03,
	null secondarysentype_03,
	llsoa_03,
	idacirank_03,
	idaciscore_03,
	recordstatus_03
from
	npd_i2."<project number>".plasc_2003
;
if object_id('npd_i2."<project number>".plasc_2004') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_04,
	object_id('npd_i2."<project number>".plasc_2004'),
	2004 year,
	0 term_id,
	yearofbirth_04,
	monthofbirth_04,
	gender_04,
	ethnicgroup_04,
	firstlanguage_04,
	laestab_anon_04,
	null onroll_04,
	enrolstatus_04,
	ncyearactual_04,
	entrydate_04,
	null leavingdate_04,
	fsmeligible_04,
	null everfsm_6_04,
	null everfsm_6_p_04,
	senstatus_04,
	primarysentype_04,
	secondarysentype_04,
	llsoa_04,
	idacirank_04,
	idaciscore_04,
	recordstatus_04
from
	npd_i2."<project number>".plasc_2004
;
if object_id('npd_i2."<project number>".plasc_2005') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_05,
	object_id('npd_i2."<project number>".plasc_2005'),
	2005 year,
	0 term_id,
	yearofbirth_05,
	monthofbirth_05,
	gender_05,
	ethnicgroup_05,
	firstlanguage_05,
	laestab_anon_05,
	null onroll_05,
	enrolstatus_05,
	ncyearactual_05,
	entrydate_05,
	null leavingdate_05,
	fsmeligible_05,
	null everfsm_6_05,
	null everfsm_6_p_05,
	senstatus_05,
	primarysentype_05,
	secondarysentype_05,
	llsoa_05,
	idacirank_05,
	idaciscore_05,
	recordstatus_05
from
	npd_i2."<project number>".plasc_2005
;
-- Spring 2006 was the first termly census (there was no Autumn 2005/6)
if object_id('npd_i2."<project number>".spring_census_2006') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr06,
	object_id('npd_i2."<project number>".spring_census_2006'),
	2006 year,
	2 term_id,
	yearofbirth_spr06,
	monthofbirth_spr06,
	gender_spr06,
	ethnicgroupminor_spr06,
	languagegroupminor_spr06,
	laestab_anon_spr06,
	null onroll_spr06,
	enrolstatus_spr06,
	ncyearactual_spr06,
	entrydate_spr06,
	null leavingdate_spr06,
	fsmeligible_spr06,
	null everfsm_6_spr06,
	null everfsm_6_p_spr06,
	senprovision_spr06,
	primarysentype_spr06,
	secondarysentype_spr06,
	llsoa_spr06,
	idacirank_spr06,
	idaciscore_spr06,
	recordstatus_spr06
from
	npd_i2."<project number>".spring_census_2006
;
if object_id('npd_i2."<project number>".summer_census_2006') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum06,
	object_id('npd_i2."<project number>".summer_census_2006'),
	2006 year,
	3 term_id,
	yearofbirth_sum06,
	monthofbirth_sum06,
	gender_sum06,
	ethnicgroup_sum06,
	firstlanguage_sum06,
	laestab_anon_sum06,
	null onroll_sum06,
	enrolstatus_sum06,
	ncyearactual_sum06,
	entrydate_sum06,
	null leavingdate_sum06,
	fsmeligible_sum06,
	null everfsm_6_sum06,
	null everfsm_6_p_sum06,
	senprovision_sum06,
	primarysentype_sum06,
	secondarysentype_sum06,
	llsoa_sum06,
	idacirank_sum06,
	idaciscore_sum06,
	recordstatus_sum06
from
	npd_i2."<project number>".summer_census_2006
;
if object_id('npd_i2."<project number>".autumn_census_2007') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut07,
	object_id('npd_i2."<project number>".autumn_census_2007'),
	2007 year,
	1 term_id,
	yearofbirth_aut07,
	monthofbirth_aut07,
	gender_aut07,
	ethnicgroup_aut07,
	firstlanguage_aut07,
	laestab_anon_aut07,
	null onroll_aut07,
	enrolstatus_aut07,
	ncyearactual_aut07,
	entrydate_aut07,
	null leavingdate_aut07,
	fsmeligible_aut07,
	null everfsm_6_aut07,
	null everfsm_6_p_aut07,
	senprovision_aut07,
	null primarysentype_aut07,
	null secondarysentype_aut07,
	llsoa_aut07,
	idacirank_aut07,
	idaciscore_aut07,
	recordstatus_aut07
from
	npd_i2."<project number>".autumn_census_2007
;
if object_id('npd_i2."<project number>".spring_census_2007') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr07,
	object_id('npd_i2."<project number>".spring_census_2007'),
	2007 year,
	2 term_id,
	yearofbirth_spr07,
	monthofbirth_spr07,
	gender_spr07,
	ethnicgroupminor_spr07,
	languagegroupminor_spr07,
	laestab_anon_spr07,
	null onroll_spr07,
	enrolstatus_spr07,
	ncyearactual_spr07,
	entrydate_spr07,
	null leavingdate_spr07,
	fsmeligible_spr07,
	null everfsm_6_spr07,
	null everfsm_6_p_spr07,
	senprovision_spr07,
	primarysentype_spr07,
	secondarysentype_spr07,
	llsoa_spr07,
	idacirank_spr07,
	idaciscore_spr07,
	recordstatus_spr07
from
	npd_i2."<project number>".spring_census_2007
;
if object_id('npd_i2."<project number>".summer_census_2007') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum07,
	object_id('npd_i2."<project number>".summer_census_2007'),
	2007 year,
	3 term_id,
	yearofbirth_sum07,
	monthofbirth_sum07,
	gender_sum07,
	ethnicgroup_sum07,
	null languagegroupminor_sum07,
	laestab_anon_sum07,
	null onroll_sum07,
	enrolstatus_sum07,
	ncyearactual_sum07,
	entrydate_sum07,
	null leavingdate_sum07,
	fsmeligible_sum07,
	null everfsm_6_sum07,
	null everfsm_6_p_sum07,
	senprovision_sum07,
	null primarysentype_sum07,
	null secondarysentype_sum07,
	llsoa_sum07,
	idacirank_sum07,
	idaciscore_sum07,
	recordstatus_sum07
from
	npd_i2."<project number>".summer_census_2007
;
if object_id('npd_i2."<project number>".autumn_census_2008') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut08,
	object_id('npd_i2."<project number>".autumn_census_2008'),
	2008 year,
	1 term_id,
	yearofbirth_aut08,
	monthofbirth_aut08,
	gender_aut08,
	ethnicgroup_aut08,
	null languagegroupminor_aut08,
	laestab_anon_aut08,
	null onroll_aut08,
	enrolstatus_aut08,
	ncyearactual_aut08,
	entrydate_aut08,
	null leavingdate_aut08,
	fsmeligible_aut08,
	null everfsm_6_aut08,
	null everfsm_6_p_aut08,
	senprovision_aut08,
	null primarysentype_aut08,
	null secondarysentype_aut08,
	llsoa_aut08,
	idacirank_aut08,
	idaciscore_aut08,
	recordstatus_aut08
from
	npd_i2."<project number>".autumn_census_2008
;
if object_id('npd_i2."<project number>".spring_census_2008') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr08,
	object_id('npd_i2."<project number>".spring_census_2008'),
	2008 year,
	2 term_id,
	yearofbirth_spr08,
	monthofbirth_spr08,
	gender_spr08,
	ethnicgroupminor_spr08,
	languagegroupminor_spr08,
	laestab_anon_spr08,
	null onroll_spr08,
	enrolstatus_spr08,
	ncyearactual_spr08,
	entrydate_spr08,
	null leavingdate_spr08,
	fsmeligible_spr08,
	null everfsm_6_spr08,
	null everfsm_6_p_spr08,
	senprovision_spr08,
	primarysentype_spr08,
	secondarysentype_spr08,
	llsoa_spr08,
	idacirank_spr08,
	idaciscore_spr08,
	recordstatus_spr08
from
	npd_i2."<project number>".spring_census_2008
;
if object_id('npd_i2."<project number>".summer_census_2008') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum08,
	object_id('npd_i2."<project number>".summer_census_2008'),
	2008 year,
	3 term_id,
	yearofbirth_sum08,
	monthofbirth_sum08,
	gender_sum08,
	ethnicgroup_sum08,
	null languagegroupminor_sum08,
	laestab_anon_sum08,
	null onroll_sum08,
	enrolstatus_sum08,
	ncyearactual_sum08,
	entrydate_sum08,
	null leavingdate_sum08,
	fsmeligible_sum08,
	null everfsm_6_sum08,
	null everfsm_6_p_sum08,
	senprovision_sum08,
	null primarysentype_sum08,
	null secondarysentype_sum08,
	llsoa_sum08,
	idacirank_sum08,
	idaciscore_sum08,
	recordstatus_sum08
from
	npd_i2."<project number>".summer_census_2008
;
if object_id('npd_i2."<project number>".autumn_census_2009') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut09,
	object_id('npd_i2."<project number>".autumn_census_2009'),
	2009 year,
	1 term_id,
	yearofbirth_aut09,
	monthofbirth_aut09,
	gender_aut09,
	ethnicgroup_aut09,
	null languagegroupminor_aut09,
	laestab_anon_aut09,
	null onroll_aut09,
	enrolstatus_aut09,
	ncyearactual_aut09,
	entrydate_aut09,
	null leavingdate_aut09,
	fsmeligible_aut09,
	null everfsm_6_aut09,
	null everfsm_6_p_aut09,
	senprovision_aut09,
	null primarysentype_aut09,
	null secondarysentype_aut09,
	llsoa_aut09,
	idacirank_aut09,
	idaciscore_aut09,
	recordstatus_aut09
from
	npd_i2."<project number>".autumn_census_2009
;
if object_id('npd_i2."<project number>".spring_census_2009') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr09,
	object_id('npd_i2."<project number>".spring_census_2009'),
	2009 year,
	2 term_id,
	yearofbirth_spr09,
	monthofbirth_spr09,
	gender_spr09,
	ethnicgroupminor_spr09,
	languagegroupminor_spr09,
	laestab_anon_spr09,
	onroll_spr09,
	enrolstatus_spr09,
	ncyearactual_spr09,
	entrydate_spr09,
	null leavingdate_spr09,
	fsmeligible_spr09,
	null everfsm_6_spr09,
	null everfsm_6_p_spr09,
	senprovision_spr09,
	primarysentype_spr09,
	secondarysentype_spr09,
	llsoa_spr09,
	idacirank_spr09,
	idaciscore_spr09,
	recordstatus_spr09
from
	npd_i2."<project number>".spring_census_2009
;
if object_id('npd_i2."<project number>".summer_census_2009') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum09,
	object_id('npd_i2."<project number>".summer_census_2009'),
	2009 year,
	3 term_id,
	yearofbirth_sum09,
	monthofbirth_sum09,
	gender_sum09,
	ethnicgroupminor_sum09,
	languagegroupminor_sum09,
	laestab_anon_sum09,
	onroll_sum09,
	enrolstatus_sum09,
	ncyearactual_sum09,
	entrydate_sum09,
	null leavingdate_sum09,
	fsmeligible_sum09,
	null everfsm_6_sum09,
	null everfsm_6_p_sum09,
	senprovision_sum09,
	null primarysentype_sum09,
	null secondarysentype_sum09,
	llsoa_sum09,
	idacirank_sum09,
	idaciscore_sum09,
	recordstatus_sum09
from
	npd_i2."<project number>".summer_census_2009
;
if object_id('npd_i2."<project number>".autumn_census_2010') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut10,
	object_id('npd_i2."<project number>".autumn_census_2010'),
	2010 year,
	1 term_id,
	yearofbirth_aut10,
	monthofbirth_aut10,
	gender_aut10,
	ethnicgroupminor_aut10,
	languagegroupminor_aut10,
	laestab_anon_aut10,
	onroll_aut10,
	enrolstatus_aut10,
	ncyearactual_aut10,
	entrydate_aut10,
	null leavingdate_aut10,
	fsmeligible_aut10,
	null everfsm_6_aut10,
	null everfsm_6_p_aut10,
	senprovision_aut10,
	null primarysentype_aut10,
	null secondarysentype_aut10,
	llsoa_aut10,
	idacirank_aut10,
	idaciscore_aut10,
	recordstatus_aut10
from
	npd_i2."<project number>".autumn_census_2010
;
if object_id('npd_i2."<project number>".spring_census_2010') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr10,
	object_id('npd_i2."<project number>".spring_census_2010'),
	2010 year,
	2 term_id,
	yearofbirth_spr10,
	monthofbirth_spr10,
	gender_spr10,
	ethnicgroupminor_spr10,
	languagegroupminor_spr10,
	laestab_anon_spr10,
	onroll_spr10,
	enrolstatus_spr10,
	ncyearactual_spr10,
	entrydate_spr10,
	null leavingdate_spr10,
	fsmeligible_spr10,
	null everfsm_6_spr10,
	null everfsm_6_p_spr10,
	senprovision_spr10,
	primarysentype_spr10,
	secondarysentype_spr10,
	llsoa_spr10,
	idacirank_spr10,
	idaciscore_spr10,
	recordstatus_spr10
from
	npd_i2."<project number>".spring_census_2010
;
if object_id('npd_i2."<project number>".summer_census_2010') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum10,
	object_id('npd_i2."<project number>".summer_census_2010'),
	2010 year,
	3 term_id,
	yearofbirth_sum10,
	monthofbirth_sum10,
	gender_sum10,
	ethnicgroupminor_sum10,
	languagegroupminor_sum10,
	laestab_anon_sum10,
	onroll_sum10,
	enrolstatus_sum10,
	ncyearactual_sum10,
	entrydate_sum10,
	null leavingdate_sum10,
	fsmeligible_sum10,
	null everfsm_6_sum10,
	null everfsm_6_p_sum10,
	senprovision_sum10,
	null primarysentype_sum10,
	null secondarysentype_sum10,
	llsoa_sum10,
	idacirank_sum10,
	idaciscore_sum10,
	recordstatus_sum10
from
	npd_i2."<project number>".summer_census_2010
;
if object_id('npd_i2."<project number>".autumn_census_2011') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut11,
	object_id('npd_i2."<project number>".autumn_census_2011'),
	2011 year,
	1 term_id,
	yearofbirth_aut11,
	monthofbirth_aut11,
	gender_aut11,
	ethnicgroupminor_aut11,
	languagegroupminor_aut11,
	laestab_anon_aut11,
	onroll_aut11,
	enrolstatus_aut11,
	ncyearactual_aut11,
	entrydate_aut11,
	null leavingdate_aut11,
	fsmeligible_aut11,
	null everfsm_6_aut11,
	null everfsm_6_p_aut11,
	senprovision_aut11,
	null primarysentype_aut11,
	null secondarysentype_aut11,
	llsoa_aut11,
	idacirank_aut11,
	idaciscore_aut11,
	recordstatus_aut11
from
	npd_i2."<project number>".autumn_census_2011
;
if object_id('npd_i2."<project number>".spring_census_2011') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr11,
	object_id('npd_i2."<project number>".spring_census_2011'),
	2011 year,
	2 term_id,
	yearofbirth_spr11,
	monthofbirth_spr11,
	gender_spr11,
	ethnicgroupminor_spr11,
	languagegroupminor_spr11,
	laestab_anon_spr11,
	onroll_spr11,
	enrolstatus_spr11,
	ncyearactual_spr11,
	entrydate_spr11,
	null leavingdate_spr11,
	fsmeligible_spr11,
	null everfsm_6_spr11,
	null everfsm_6_p_spr11,
	senprovision_spr11,
	primarysentype_spr11,
	secondarysentype_spr11,
	llsoa_spr11,
	idacirank_spr11,
	idaciscore_spr11,
	recordstatus_spr11
from
	npd_i2."<project number>".spring_census_2011
;
if object_id('npd_i2."<project number>".summer_census_2011') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum11,
	object_id('npd_i2."<project number>".summer_census_2011'),
	2011 year,
	3 term_id,
	yearofbirth_sum11,
	monthofbirth_sum11,
	gender_sum11,
	null ethnicgroupminor_sum11,
	languagegroupminor_sum11,
	laestab_anon_sum11,
	onroll_sum11,
	enrolstatus_sum11,
	ncyearactual_sum11,
	entrydate_sum11,
	null leavingdate_sum11,
	fsmeligible_sum11,
	null everfsm_6_sum11,
	null everfsm_6_p_sum11,
	senprovision_sum11,
	null primarysentype_sum11,
	null secondarysentype_sum11,
	null llsoa_sum11,
	null idacirank_sum11,
	null idaciscore_sum11,
	recordstatus_sum11
from
	npd_i2."<project number>".summer_census_2011
;
if object_id('npd_i2."<project number>".autumn_census_2012') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut12,
	object_id('npd_i2."<project number>".autumn_census_2012'),
	2012 year,
	1 term_id,
	yearofbirth_aut12,
	monthofbirth_aut12,
	gender_aut12,
	null ethnicgroupminor_aut12,
	languagegroupminor_aut12,
	laestab_anon_aut12,
	onroll_aut12,
	enrolstatus_aut12,
	ncyearactual_aut12,
	entrydate_aut12,
	null leavingdate_aut12,
	fsmeligible_aut12,
	null everfsm_6_aut12,
	null everfsm_6_p_aut12,
	senprovision_aut12,
	null primarysentype_aut12,
	null secondarysentype_aut12,
	null llsoa_aut12,
	null idacirank_aut12,
	null idaciscore_aut12,
	recordstatus_aut12
from
	npd_i2."<project number>".autumn_census_2012
;
if object_id('npd_i2."<project number>".spring_census_2012') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr12,
	object_id('npd_i2."<project number>".spring_census_2012'),
	2012 year,
	2 term_id,
	yearofbirth_spr12,
	monthofbirth_spr12,
	gender_spr12,
	ethnicgroupminor_spr12,
	languagegroupminor_spr12,
	laestab_anon_spr12,
	onroll_spr12,
	enrolstatus_spr12,
	ncyearactual_spr12,
	entrydate_spr12,
	null leavingdate_spr12,
	fsmeligible_spr12,
	null everfsm_6_spr12,
	null everfsm_6_p_spr12,
	senprovision_spr12,
	primarysentype_spr12,
	secondarysentype_spr12,
	llsoa_spr12,
	idacirank_spr12,
	idaciscore_spr12,
	recordstatus_spr12
from
	npd_i2."<project number>".spring_census_2012
;
if object_id('npd_i2."<project number>".summer_census_2012') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum12,
	object_id('npd_i2."<project number>".summer_census_2012'),
	2012 year,
	3 term_id,
	yearofbirth_sum12,
	monthofbirth_sum12,
	gender_sum12,
	null ethnicgroupminor_sum12,
	languagegroupminor_sum12,
	laestab_anon_sum12,
	onroll_sum12,
	enrolstatus_sum12,
	ncyearactual_sum12,
	entrydate_sum12,
	null leavingdate_sum12,
	fsmeligible_sum12,
	null everfsm_6_sum12,
	null everfsm_6_p_sum12,
	senprovision_sum12,
	null primarysentype_sum12,
	null secondarysentype_sum12,
	llsoa_sum12,
	idacirank_sum12,
	idaciscore_sum12,
	recordstatus_sum12
from
	npd_i2."<project number>".summer_census_2012
;
if object_id('npd_i2."<project number>".autumn_census_2013') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut13,
	object_id('npd_i2."<project number>".autumn_census_2013'),
	2013 year,
	1 term_id,
	yearofbirth_aut13,
	monthofbirth_aut13,
	gender_aut13,
	null ethnicgroupminor_aut13,
	languagegroupminor_aut13,
	laestab_anon_aut13,
	onroll_aut13,
	enrolstatus_aut13,
	ncyearactual_aut13,
	entrydate_aut13,
	null leavingdate_aut13,
	fsmeligible_aut13,
	null everfsm_6_aut13,
	null everfsm_6_p_aut13,
	senprovision_aut13,
	null primarysentype_aut13,
	null secondarysentype_aut13,
	llsoa_aut13,
	idacirank_aut13,
	idaciscore_aut13,
	recordstatus_aut13
from
	npd_i2."<project number>".autumn_census_2013
;
if object_id('npd_i2."<project number>".spring_census_2013') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr13,
	object_id('npd_i2."<project number>".spring_census_2013'),
	2013 year,
	2 term_id,
	yearofbirth_spr13,
	monthofbirth_spr13,
	gender_spr13,
	ethnicgroupminor_spr13,
	languagegroupminor_spr13,
	laestab_anon_spr13,
	onroll_spr13,
	enrolstatus_spr13,
	ncyearactual_spr13,
	entrydate_spr13,
	null leavingdate_spr13,
	fsmeligible_spr13,
	null everfsm_6_spr13,
	null everfsm_6_p_spr13,
	senprovision_spr13,
	primarysentype_spr13,
	secondarysentype_spr13,
	lsoa11_spr13,
	idacirank_spr13,
	idaciscore_spr13,
	recordstatus_spr13
from
	npd_i2."<project number>".spring_census_2013
;
if object_id('npd_i2."<project number>".summer_census_2013') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum13,
	object_id('npd_i2."<project number>".summer_census_2013'),
	2013 year,
	3 term_id,
	yearofbirth_sum13,
	monthofbirth_sum13,
	gender_sum13,
	null ethnicgroupminor_sum13,
	languagegroupminor_sum13,
	laestab_anon_sum13,
	onroll_sum13,
	enrolstatus_sum13,
	ncyearactual_sum13,
	entrydate_sum13,
	null leavingdate_sum13,
	fsmeligible_sum13,
	null everfsm_6_sum13,
	null everfsm_6_p_sum13,
	senprovision_sum13,
	null primarysentype_sum13,
	null secondarysentype_sum13,
	lsoa11_sum13,
	idacirank_sum13,
	idaciscore_sum13,
	recordstatus_sum13
from
	npd_i2."<project number>".summer_census_2013
;
if object_id('npd_i2."<project number>".autumn_census_2014') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut14,
	object_id('npd_i2."<project number>".autumn_census_2014'),
	2014 year,
	1 term_id,
	yearofbirth_aut14,
	monthofbirth_aut14,
	gender_aut14,
	null ethnicgroupminor_aut14,
	languagegroupminor_aut14,
	laestab_anon_aut14,
	onroll_aut14,
	enrolstatus_aut14,
	ncyearactual_aut14,
	entrydate_aut14,
	null leavingdate_aut14,
	fsmeligible_aut14,
	null everfsm_6_aut14,
	null everfsm_6_p_aut14,
	senprovision_aut14,
	null primarysentype_aut14,
	null secondarysentype_aut14,
	lsoa11_aut14,
	idacirank_aut14,
	idaciscore_aut14,
	recordstatus_aut14
from
	npd_i2."<project number>".autumn_census_2014
;
if object_id('npd_i2."<project number>".spring_census_2014') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr14,
	object_id('npd_i2."<project number>".spring_census_2014'),
	2014 year,
	2 term_id,
	yearofbirth_spr14,
	monthofbirth_spr14,
	gender_spr14,
	ethnicgroupminor_spr14,
	languagegroupminor_spr14,
	laestab_anon_spr14,
	onroll_spr14,
	enrolstatus_spr14,
	ncyearactual_spr14,
	entrydate_spr14,
	null leavingdate_spr14,
	fsmeligible_spr14,
	null everfsm_6_spr14,
	null everfsm_6_p_spr14,
	senprovision_spr14,
	primarysentype_spr14,
	secondarysentype_spr14,
	lsoa11_spr14,
	idacirank_spr14,
	idaciscore_spr14,
	recordstatus_spr14
from
	npd_i2."<project number>".spring_census_2014
;
if object_id('npd_i2."<project number>".summer_census_2014') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum14,
	object_id('npd_i2."<project number>".summer_census_2014'),
	2014 year,
	3 term_id,
	yearofbirth_sum14,
	monthofbirth_sum14,
	gender_sum14,
	null ethnicgroupminor_sum14,
	languagegroupminor_sum14,
	laestab_anon_sum14,
	onroll_sum14,
	enrolstatus_sum14,
	ncyearactual_sum14,
	entrydate_sum14,
	null leavingdate_sum14,
	fsmeligible_sum14,
	null everfsm_6_sum14,
	null everfsm_6_p_sum14,
	senprovision_sum14,
	null primarysentype_sum14,
	null secondarysentype_sum14,
	lsoa11_sum14,
	idacirank_sum14,
	idaciscore_sum14,
	recordstatus_sum14
from
	npd_i2."<project number>".summer_census_2014
;
if object_id('npd_i2."<project number>".autumn_census_2015') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut15,
	object_id('npd_i2."<project number>".autumn_census_2015'),
	2015 year,
	1 term_id,
	yearofbirth_aut15,
	monthofbirth_aut15,
	gender_aut15,
	null ethnicgroupminor_aut15,
	languagegroupminor_aut15,
	laestab_anon_aut15,
	onroll_aut15,
	enrolstatus_aut15,
	ncyearactual_aut15,
	entrydate_aut15,
	null leavingdate_aut15,
	fsmeligible_aut15,
	null everfsm_6_aut15,
	null everfsm_6_p_aut15,
	senprovision_aut15,
	null primarysentype_aut15,
	null secondarysentype_aut15,
	lsoa11_aut15,
	idacirank_aut15,
	idaciscore_aut15,
	recordstatus_aut15
from
	npd_i2."<project number>".autumn_census_2015
;
if object_id('npd_i2."<project number>".spring_census_2015') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr15,
	object_id('npd_i2."<project number>".spring_census_2015'),
	2015 year,
	2 term_id,
	yearofbirth_spr15,
	monthofbirth_spr15,
	gender_spr15,
	ethnicgroupminor_spr15,
	languagegroupminor_spr15,
	laestab_anon_spr15,
	onroll_spr15,
	enrolstatus_spr15,
	ncyearactual_spr15,
	entrydate_spr15,
	null leavingdate_spr15,
	fsmeligible_spr15,
	null everfsm_6_spr15,
	null everfsm_6_p_spr15,
	senprovision_spr15,
	primarysentype_spr15,
	secondarysentype_spr15,
	lsoa11_spr15,
	idacirank_spr15,
	idaciscore_spr15,
	recordstatus_spr15
from
	npd_i2."<project number>".spring_census_2015
;
if object_id('npd_i2."<project number>".summer_census_2015') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum15,
	object_id('npd_i2."<project number>".summer_census_2015'),
	2015 year,
	3 term_id,
	yearofbirth_sum15,
	monthofbirth_sum15,
	gender_sum15,
	null ethnicgroupminor_sum15,
	languagegroupminor_sum15,
	laestab_anon_sum15,
	onroll_sum15,
	enrolstatus_sum15,
	ncyearactual_sum15,
	entrydate_sum15,
	null leavingdate_sum15,
	fsmeligible_sum15,
	null everfsm_6_sum15,
	null everfsm_6_p_sum15,
	senprovision_sum15,
	null primarysentype_sum15,
	null secondarysentype_sum15,
	lsoa11_sum15,
	idacirank_sum15,
	idaciscore_sum15,
	recordstatus_sum15
from
	npd_i2."<project number>".summer_census_2015
;
if object_id('npd_i2."<project number>".autumn_census_2016') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut16,
	object_id('npd_i2."<project number>".autumn_census_2016'),
	2016 year,
	1 term_id,
	yearofbirth_aut16,
	monthofbirth_aut16,
	gender_aut16,
	null ethnicgroupminor_aut16,
	languagegroupminor_aut16,
	laestab_anon_aut16,
	onroll_aut16,
	enrolstatus_aut16,
	ncyearactual_aut16,
	entrydate_aut16,
	null leavingdate_aut16,
	fsmeligible_aut16,
	null everfsm_6_aut16,
	null everfsm_6_p_aut16,
	senprovision_aut16,
	null primarysentype_aut16,
	null secondarysentype_aut16,
	lsoa11_aut16,
	idacirank_10_aut16,
	idaciscore_10_aut16,
	recordstatus_aut16
from
	npd_i2."<project number>".autumn_census_2016
;
if object_id('npd_i2."<project number>".spring_census_2016') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr16,
	object_id('npd_i2."<project number>".spring_census_2016'),
	2016 year,
	2 term_id,
	yearofbirth_spr16,
	monthofbirth_spr16,
	gender_spr16,
	ethnicgroupminor_spr16,
	languagegroupminor_spr16,
	laestab_anon_spr16,
	onroll_spr16,
	enrolstatus_spr16,
	ncyearactual_spr16,
	entrydate_spr16,
	null leavingdate_spr16,
	fsmeligible_spr16,
	null everfsm_6_spr16,
	everfsm_6_p_spr16,
	senprovision_spr16,
	primarysentype_spr16,
	secondarysentype_spr16,
	lsoa11_spr16,
	idacirank_10_spr16,
	idaciscore_10_spr16,
	recordstatus_spr16
from
	npd_i2."<project number>".spring_census_2016
;
if object_id('npd_i2."<project number>".summer_census_2016') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum16,
	object_id('npd_i2."<project number>".summer_census_2016'),
	2016 year,
	3 term_id,
	yearofbirth_sum16,
	monthofbirth_sum16,
	gender_sum16,
	null ethnicgroupminor_sum16,
	languagegroupminor_sum16,
	laestab_anon_sum16,
	onroll_sum16,
	enrolstatus_sum16,
	ncyearactual_sum16,
	entrydate_sum16,
	null leavingdate_sum16,
	fsmeligible_sum16,
	null everfsm_6_sum16,
	null everfsm_6_p_sum16,
	senprovision_sum16,
	null primarysentype_sum16,
	null secondarysentype_sum16,
	lsoa11_sum16,
	idacirank_10_sum16,
	idaciscore_10_sum16,
	recordstatus_sum16
from
	npd_i2."<project number>".summer_census_2016
;
if object_id('npd_i2."<project number>".autumn_census_2017') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut17,
	object_id('npd_i2."<project number>".autumn_census_2017'),
	2017 year,
	1 term_id,
	yearofbirth_aut17,
	monthofbirth_aut17,
	gender_aut17,
	null ethnicgroupminor_aut17,
	languagegroupminor_aut17,
	laestab_anon_aut17,
	onroll_aut17,
	enrolstatus_aut17,
	ncyearactual_aut17,
	entrydate_aut17,
	null leavingdate_aut17,
	fsmeligible_aut17,
	null everfsm_6_aut17,
	null everfsm_6_p_aut17,
	senprovision_aut17,
	null primarysentype_aut17,
	null secondarysentype_aut17,
	lsoa11_aut17,
	idacirank_15_aut17,
	idaciscore_15_aut17,
	recordstatus_aut17
from
	npd_i2."<project number>".autumn_census_2017
;
if object_id('npd_i2."<project number>".spring_census_2017') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr17,
	object_id('npd_i2."<project number>".spring_census_2017'),
	2017 year,
	2 term_id,
	yearofbirth_spr17,
	monthofbirth_spr17,
	gender_spr17,
	ethnicgroupminor_spr17,
	languagegroupminor_spr17,
	laestab_anon_spr17,
	onroll_spr17,
	enrolstatus_spr17,
	ncyearactual_spr17,
	entrydate_spr17,
	null leavingdate_spr17,
	fsmeligible_spr17,
	null everfsm_6_spr17,
	everfsm_6_p_spr17,
	senprovision_spr17,
	primarysentype_spr17,
	secondarysentype_spr17,
	lsoa11_spr17,
	idacirank_15_spr17,
	idaciscore_15_spr17,
	recordstatus_spr17
from
	npd_i2."<project number>".spring_census_2017
;
if object_id('npd_i2."<project number>".summer_census_2017') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum17,
	object_id('npd_i2."<project number>".summer_census_2017'),
	2017 year,
	3 term_id,
	yearofbirth_sum17,
	monthofbirth_sum17,
	gender_sum17,
	null ethnicgroupminor_sum17,
	languagegroupminor_sum17,
	laestab_anon_sum17,
	onroll_sum17,
	enrolstatus_sum17,
	ncyearactual_sum17,
	entrydate_sum17,
	null leavingdate_sum17,
	fsmeligible_sum17,
	null everfsm_6_sum17,
	null everfsm_6_p_sum17,
	senprovision_sum17,
	null primarysentype_sum17,
	null secondarysentype_sum17,
	lsoa11_sum17,
	idacirank_15_sum17,
	idaciscore_15_sum17,
	recordstatus_sum17
from
	npd_i2."<project number>".summer_census_2017
;
if object_id('npd_i2."<project number>".autumn_census_2018') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut18,
	object_id('npd_i2."<project number>".autumn_census_2018'),
	2018 year,
	1 term_id,
	yearofbirth_aut18,
	monthofbirth_aut18,
	gender_aut18,
	null ethnicgroupminor_aut18,
	languagegroupminor_aut18,
	laestab_anon_aut18,
	onroll_aut18,
	enrolstatus_aut18,
	ncyearactual_aut18,
	entrydate_aut18,
	null leavingdate_aut18,
	fsmeligible_aut18,
	null everfsm_6_aut18,
	null everfsm_6_p_aut18,
	senprovision_aut18,
	null primarysentype_aut18,
	null secondarysentype_aut18,
	lsoa11_aut18,
	idacirank_15_aut18,
	idaciscore_15_aut18,
	recordstatus_aut18
from
	npd_i2."<project number>".autumn_census_2018
;
if object_id('npd_i2."<project number>".spring_census_2018') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr18,
	object_id('npd_i2."<project number>".spring_census_2018'),
	2018 year,
	2 term_id,
	yearofbirth_spr18,
	monthofbirth_spr18,
	gender_spr18,
	ethnicgroupminor_spr18,
	languagegroupminor_spr18,
	laestab_anon_spr18,
	onroll_spr18,
	enrolstatus_spr18,
	ncyearactual_spr18,
	entrydate_spr18,
	null leavingdate_spr18,
	fsmeligible_spr18,
	null everfsm_6_spr18,
	everfsm_6_p_spr18,
	senprovision_spr18,
	primarysentype_spr18,
	secondarysentype_spr18,
	lsoa11_spr18,
	idacirank_15_spr18,
	idaciscore_15_spr18,
	recordstatus_spr18
from
	npd_i2."<project number>".spring_census_2018
;
if object_id('npd_i2."<project number>".summer_census_2018') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum18,
	object_id('npd_i2."<project number>".summer_census_2018'),
	2018 year,
	3 term_id,
	yearofbirth_sum18,
	monthofbirth_sum18,
	gender_sum18,
	null ethnicgroupminor_sum18,
	languagegroupminor_sum18,
	laestab_anon_sum18,
	onroll_sum18,
	enrolstatus_sum18,
	ncyearactual_sum18,
	entrydate_sum18,
	null leavingdate_sum18,
	fsmeligible_sum18,
	null everfsm_6_sum18,
	null everfsm_6_p_sum18,
	senprovision_sum18,
	null primarysentype_sum18,
	null secondarysentype_sum18,
	lsoa11_sum18,
	idacirank_15_sum18,
	idaciscore_15_sum18,
	recordstatus_sum18
from
	npd_i2."<project number>".summer_census_2018
;
if object_id('npd_i2."<project number>".autumn_census_2019') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut19,
	object_id('npd_i2."<project number>".autumn_census_2019'),
	2019 year,
	1 term_id,
	yearofbirth_aut19,
	monthofbirth_aut19,
	gender_aut19,
	null ethnicgroupminor_aut19,
	languagegroupminor_aut19,
	laestab_anon_aut19,
	onroll_aut19,
	enrolstatus_aut19,
	ncyearactual_aut19,
	entrydate_aut19,
	null leavingdate_aut19,
	fsmeligible_aut19,
	null everfsm_6_aut19,
	null everfsm_6_p_aut19,
	senprovision_aut19,
	null primarysentype_aut19,
	null secondarysentype_aut19,
	lsoa11_aut19,
	idacirank_15_aut19,
	idaciscore_15_aut19,
	recordstatus_aut19
from
	npd_i2."<project number>".autumn_census_2019
;
if object_id('npd_i2."<project number>".spring_census_2019') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr19,
	object_id('npd_i2."<project number>".spring_census_2019'),
	2019 year,
	2 term_id,
	yearofbirth_spr19,
	monthofbirth_spr19,
	gender_spr19,
	ethnicgroupminor_spr19,
	languagegroupminor_spr19,
	laestab_anon_spr19,
	onroll_spr19,
	enrolstatus_spr19,
	ncyearactual_spr19,
	entrydate_spr19,
	null leavingdate_spr19,
	fsmeligible_spr19,
	null everfsm_6_spr19,
	everfsm_6_p_spr19,
	senprovision_spr19,
	primarysentype_spr19,
	secondarysentype_spr19,
	lsoa11_spr19,
	idacirank_15_spr19,
	idaciscore_15_spr19,
	recordstatus_spr19
from
	npd_i2."<project number>".spring_census_2019
;
if object_id('npd_i2."<project number>".summer_census_2019') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum19,
	object_id('npd_i2."<project number>".summer_census_2019'),
	2019 year,
	3 term_id,
	yearofbirth_sum19,
	monthofbirth_sum19,
	gender_sum19,
	null ethnicgroupminor_sum19,
	languagegroupminor_sum19,
	laestab_anon_sum19,
	onroll_sum19,
	enrolstatus_sum19,
	ncyearactual_sum19,
	entrydate_sum19,
	null leavingdate_sum19,
	fsmeligible_sum19,
	null everfsm_6_sum19,
	null everfsm_6_p_sum19,
	senprovision_sum19,
	null primarysentype_sum19,
	null secondarysentype_sum19,
	lsoa11_sum19,
	idacirank_15_sum19,
	idaciscore_15_sum19,
	recordstatus_sum19
from
	npd_i2."<project number>".summer_census_2019
;
if object_id('npd_i2."<project number>".autumn_census_2020') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut20,
	object_id('npd_i2."<project number>".autumn_census_2020'),
	2020 year,
	1 term_id,
	yearofbirth_aut20,
	monthofbirth_aut20,
	gender_aut20,
	null ethnicgroupminor_aut20,
	languagegroupminor_aut20,
	laestab_anon_aut20,
	onroll_aut20,
	enrolstatus_aut20,
	ncyearactual_aut20,
	entrydate_aut20,
	null leavingdate_aut20,
	fsmeligible_aut20,
	null everfsm_6_aut20,
	null everfsm_6_p_aut20,
	senprovision_aut20,
	null primarysentype_aut20,
	null secondarysentype_aut20,
	lsoa11_aut20,
	null idacirank_15_aut20,
	null idaciscore_15_aut20,
	recordstatus_aut20
from
	npd_i2."<project number>".autumn_census_2020
;
if object_id('npd_i2."<project number>".spring_census_2020') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr20,
	object_id('npd_i2."<project number>".spring_census_2020'),
	2020 year,
	2 term_id,
	yearofbirth_spr20,
	monthofbirth_spr20,
	gender_spr20,
	ethnicgroupminor_spr20,
	languagegroupminor_spr20,
	laestab_anon_spr20,
	onroll_spr20,
	enrolstatus_spr20,
	ncyearactual_spr20,
	entrydate_spr20,
	null leavingdate_spr20,
	fsmeligible_spr20,
	null everfsm_6_spr20,
	everfsm_6_p_spr20,
	senprovision_spr20,
	primarysentype_spr20,
	secondarysentype_spr20,
	lsoa11_spr20,
	null idacirank_15_spr20,
	null idaciscore_15_spr20,
	recordstatus_spr20
from
	npd_i2."<project number>".spring_census_2020
;

-- there was no census in Summer '20 due to COVID

if object_id('npd_i2."<project number>".autumn_census_2021') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut21,
	object_id('npd_i2."<project number>".autumn_census_2021'),
	2021 year,
	1 term_id,
	yearofbirth_aut21,
	monthofbirth_aut21,
	gender_aut21,
	ethnicgroupminor_aut21,
	firstlanguage_aut21,
	laestab_anon_aut21,
	onroll_aut21,
	enrolstatus_aut21,
	ncyearactual_aut21,
	entrydate_aut21,
	null leavingdate_aut21,
	fsmeligible_aut21,
	null everfsm_6_aut21,
	null everfsm_6_p_aut21,
	senprovision_aut21,
	null primarysentype_aut21,
	null secondarysentype_aut21,
	llsoa_aut21,
	idacirank_aut21,
	idaciscore_aut21,
	recordstatus_aut21
from
	npd_i2."<project number>".autumn_census_2021
;
if object_id('npd_i2."<project number>".spring_census_2021') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr21,
	object_id('npd_i2."<project number>".spring_census_2021'),
	2021 year,
	2 term_id,
	yearofbirth_spr21,
	monthofbirth_spr21,
	gender_spr21,
	ethnicgroupminor_spr21,
	firstlanguage_spr21,
	laestab_anon_spr21,
	onroll_spr21,
	enrolstatus_spr21,
	ncyearactual_spr21,
	entrydate_spr21,
	null leavingdate_spr21,
	fsmeligible_spr21,
	null everfsm_6_spr21,
	null everfsm_6_p_spr21,
	senprovision_spr21,
	primarysentype_spr21,
	secondarysentype_spr21,
	llsoa_spr21,
	idacirank_spr21,
	idaciscore_spr21,
	recordstatus_spr21
from
	npd_i2."<project number>".spring_census_2021
;
if object_id('npd_i2."<project number>".summer_census_2021') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum21,
	object_id('npd_i2."<project number>".summer_census_2021'),
	2021 year,
	3 term_id,
	yearofbirth_sum21,
	monthofbirth_sum21,
	gender_sum21,
	ethnicgroupminor_sum21,
	firstlanguage_sum21,
	laestab_anon_sum21,
	onroll_sum21,
	enrolstatus_sum21,
	ncyearactual_sum21,
	entrydate_sum21,
	null leavingdate_sum21,
	fsmeligible_sum21,
	null everfsm_6_sum21,
	null everfsm_6_p_sum21,
	senprovision_sum21,
	null primarysentype_sum21,
	null secondarysentype_sum21,
	llsoa_sum21,
	idacirank_sum21,
	idaciscore_sum21,
	recordstatus_sum21
from
	npd_i2."<project number>".summer_census_2021
;
if object_id('npd_i2."<project number>".autumn_census_2022') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_aut22,
	object_id('npd_i2."<project number>".autumn_census_2022'),
	2022 year,
	1 term_id,
	yearofbirth_aut22,
	monthofbirth_aut22,
	gender_aut22,
	ethnicgroupminor_aut22,
	firstlanguage_aut22,
	laestab_anon_aut22,
	onroll_aut22,
	enrolstatus_aut22,
	ncyearactual_aut22,
	entrydate_aut22,
	null leavingdate_aut22,
	fsmeligible_aut22,
	null everfsm_6_aut22,
	null everfsm_6_p_aut22,
	senprovision_aut22,
	null primarysentype_aut22,
	null secondarysentype_aut22,
	llsoa_aut22,
	idacirank_aut22,
	idaciscore_aut22,
	recordstatus_aut22
from
	npd_i2."<project number>".autumn_census_2022
;
if object_id('npd_i2."<project number>".spring_census_2022') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_spr22,
	object_id('npd_i2."<project number>".spring_census_2022'),
	2022 year,
	2 term_id,
	yearofbirth_spr22,
	monthofbirth_spr22,
	gender_spr22,
	ethnicgroupminor_spr22,
	firstlanguage_spr22,
	laestab_anon_spr22,
	onroll_spr22,
	enrolstatus_spr22,
	ncyearactual_spr22,
	entrydate_spr22,
	null leavingdate_spr22,
	fsmeligible_spr22,
	null everfsm_6_spr22,
	null everfsm_6_p_spr22,
	senprovision_spr22,
	primarysentype_spr22,
	secondarysentype_spr22,
	llsoa_spr22,
	idacirank_spr22,
	idaciscore_spr22,
	recordstatus_spr22
from
	npd_i2."<project number>".spring_census_2022
;
if object_id('npd_i2."<project number>".summer_census_2022') is not null
insert fft.wip#sc
select
	pupilmatchingrefanonymous_sum22,
	object_id('npd_i2."<project number>".summer_census_2022'),
	2022 year,
	3 term_id,
	yearofbirth_sum22,
	monthofbirth_sum22,
	gender_sum22,
	ethnicgroupminor_sum22,
	firstlanguage_sum22,
	laestab_anon_sum22,
	onroll_sum22,
	enrolstatus_sum22,
	ncyearactual_sum22,
	entrydate_sum22,
	null leavingdate_sum22,
	fsmeligible_sum22,
	null everfsm_6_sum22,
	null everfsm_6_p_sum22,
	senprovision_sum22,
	null primarysentype_sum22,
	null secondarysentype_sum22,
	llsoa_sum22,
	idacirank_sum22,
	idaciscore_sum22,
	recordstatus_sum22
from
	npd_i2."<project number>".summer_census_2022
;

--------------------------------------------------------------------------------
-- person resolution
--------------------------------------------------------------------------------

if object_id('fft.person_lookup') is null
begin
create table fft.person_lookup (
	fft_person_id int not null,
	multiplex tinyint not null,
	ae_id bigint,
	pupil_matching_reference char(18) collate Latin1_General_BIN,
	ilr_external_id bigint,
	leo_edukey char(14) collate Latin1_General_BIN
	);
create unique index ix_ae_id on fft.person_lookup (ae_id)
	include (fft_person_id, multiplex);
create unique index ix_pmr on fft.person_lookup (pupil_matching_reference)
	include (fft_person_id, multiplex);
create unique index ix_external_id on fft.person_lookup (ilr_external_id)
	include (fft_person_id, multiplex);
create unique index ix_edukey on fft.person_lookup (leo_edukey)
	include (fft_person_id, multiplex);
end

-- This odd #lookup construction proved necessary in at least one project to
-- avoid issues loading data from learner_ae_id_to_pmr_lookup diectly into any
-- table without limiting it to a set number of records (which the execution
-- planner could then use to allocate appropriate space) and the insert
-- statement never finishing.

if object_id('tempdb..#lookup') is null
create table #lookup (
	ae_id bigint not null,
	pupil_matching_reference char(18) collate Latin1_General_BIN not null
	);
else truncate table #lookup;

declare @ae_id bigint = 0

while 1 = 1
begin
	insert #lookup
	select top 1000000 with ties
		ae_id,
		PupilMatchingRefAnonymous
	from
		LEO_i2."<project number>".learner_ae_id_to_pmr_lookup
	where
		ae_id > @ae_id
	group by
		ae_id,
		PupilMatchingRefAnonymous
	order by
		ae_id
	;
	if @@rowcount < 1000000
		break;
	
	select @ae_id = max(ae_id) from #lookup;
end

insert fft.person_lookup
select
	fft_person_id,
	multiplex,
	case multiplex when 1 then ae_id end,
	pupil_matching_reference,
	null external_id,
	null edukey
from
	(
	select
		*,
		fft_person_id = (select isnull(max(fft_person_id), 0) from fft.person_lookup)
			+ dense_rank() over (order by ae_id),
		multiplex = row_number() over (
			partition by ae_id
			order by (select 1)
			)
	from
		#lookup
	where
		ae_id not in (
		select ae_id
		from fft.person_lookup
		where ae_id is not null
		)
	) _
;

update pl
set pupil_matching_reference = pmr
from
	fft.person_lookup pl
	inner join (
	select
		ae_id,
		pmr = min(pupil_matching_reference)
	from
		#lookup
	group by
		ae_id
	) lk
		on	pl.ae_id = lk.ae_id
where
	pupil_matching_reference is null
	and multiplex = 1
;
insert fft.person_lookup
select
	fft_person_id,
	(select max(multiplex) from fft.person_lookup where fft_person_id = pl.fft_person_id) + r multiplex,
	null ae_id,
	pupil_matching_reference,
	null external_id,
	null edukey
from
	(
	select
		lk.pupil_matching_reference,
		fft_person_id = min(fft_person_id),
		r = row_number() over (partition by min(fft_person_id) order by (select 1))
	from
		fft.person_lookup pl
		inner join #lookup lk
			on	pl.ae_id = lk.ae_id
	where not exists (
		select *
		from (
			select
				pupil_matching_reference,
				ae_id = min(ae_id) over (partition by fft_person_id)
			from
				fft.person_lookup
			) _
		where
			pupil_matching_reference = lk.pupil_matching_reference
			and ae_id = lk.ae_id
		)
	group by
		lk.pupil_matching_reference
	) pl
;
insert fft.person_lookup
select
	(select max(fft_person_id) from fft.person_lookup)
	+ row_number() over (order by (select 1)),
	1 multiplex,
	null ae_id,
	pmr pupil_matching_reference,
	null external_id,
	null edukey
from
	(
	select distinct pmr
	from fft.wip#sc
	where
		pmr <> ''
		and pmr not in (
		select pupil_matching_reference
		from fft.person_lookup
		where pupil_matching_reference is not null
		)
	) _
;

drop table #lookup;

--------------------------------------------------------------------------------
-- institution resolution
--------------------------------------------------------------------------------

if object_id('fft.laestab_anon') is null
create table fft.laestab_anon (
	institution_id int not null primary key,
	laestab_anon varchar(30) collate Latin1_General_BIN not null
	);

insert fft.laestab_anon
select
	(
	select isnull(max(institution_id), 1e8)
	from fft.laestab_anon
	where institution_id between 1e8 and 2e8-1
	)
	+ row_number() over (order by (select 1)),
	laestab_anon
from
	(
	select laestab_anon from fft.wip#sc
	union all select pru_laestab_anon collate Latin1_General_BIN
	from npd_i2."<project number>".pru_census_2010_to_2013
	) _
where
	laestab_anon <> ''
	and laestab_anon not in (
		select laestab_anon
		from fft.laestab_anon
		)
group by
	laestab_anon
;

--------------------------------------------------------------------------------
-- main load start
--------------------------------------------------------------------------------

-- On occasion we have had the load fail when it is not batched, though it is
-- inconsistent. We load in fft_person_id order (rather than uses something more
-- obvious, such as year) to reduce data fragmentation, since fft_person_id is
-- the first column in the primary key, which is the clustered index.

declare @id int = 0;
declare @max_id int;

select
	@id = min(fft_person_id),
	@max_id = max(fft_person_id) + 1
from
	fft.person_lookup
where
	pupil_matching_reference is not null
;

declare @batch_size int = (@max_id - @id) / 10;

while @id < @max_id
begin
	insert fft.census_details
	select
		pmr pupil_matching_reference,
		year,
		term_id,
		-- this guard is added against obvious data errors, which are known to
		-- exist, for example where a pupil appears in census before their year
		-- of birth (which would cause overflow on the tinyint data type).
		case when year - acyob between 0 and 120 then year - acyob - 1 end,
		yob year_of_birth,
		mob month_of_birth,
		case left(gender, 1)
			when 'B' then 'M'
			when 'G' then 'F'
			else nullif(left(gender, 1), '')
		end gender,
		-- truncate to legal code length, though descriptions, etc. have been
		-- observed in source in practice
		left(ethnicity, 4) ethnicity,
		-- truncate to legal code length, though descriptions, etc. have been
		-- observed in source in practice
		left(flang, 3) first_language,
		null ap_type,
		onroll,
		enrol_status,
		ncy,
		entry_date,
		leaving_date,
		fsm,
		fsm6,
		fsm6p,
		-- sen status uses different code sets in different years; this resolves
		-- much of that by translating old codes to new
		case sen
			when 'S' then 'E'
			when 'A' then 'K'
			when 'P' then 'K'
			-- non-legal codes have been observed, generally where an SEN type
			-- is used instead
			else nullif(left(sen, 1), '')
		end,
		primary_sen,
		secondary_sen,
		idaci_rank,
		idaci_score,
		record_status,
		fft_person_id,
		institution_id,
		-- disambiguating row_id; we prioritise (give a lower row_id to) records
		-- relating to a pupil's main enrolment and on-roll records
		row_id = row_number() over (
			partition by fft_person_id, year, institution_id, term_id
			order by case
				when enrol_status in ('C', 'M') then 1
				when onroll = 1 then 2
				else 3
			end
			),
		-- old style LSOAs have been observed occasionally, but are rare and
		-- hence ignored
		case when len(lsoa) = 9 and isnumeric(right(lsoa, 8)) = 1 then left(lsoa, 1) end,
		case when len(lsoa) = 9 and isnumeric(right(lsoa, 8)) = 1 then right(lsoa, 8) end,
		source_id
	from
		(
		select fft_person_id, pupil_matching_reference
		from fft.person_lookup
		where
			fft_person_id >= @id
			and fft_person_id < @id + @batch_size
			and pupil_matching_reference is not null
		) lkp
		inner join fft.wip#sc sc
			on	sc.pmr = lkp.pupil_matching_reference
		outer apply (
			select acyob = yob + case when mob >= 9 then 1 else 0 end
			) acyob
		left join fft.laestab_anon s on s.laestab_anon = sc.laestab_anon
	;
	set @id += @batch_size;
end

-- a lot of these columns are fixed null since the column does not appear in the
-- source object.
insert fft.census_details
select
	ap_pupilmatchingrefanonymous,
	year,
	term_id,
	case when year - acyob between 0 and 120 then year - acyob - 1 end,
	yob year_of_birth,
	mob month_of_birth,
	case left(ap_gender, 1)
		when 'B' then 'M'
		when 'G' then 'F'
		else nullif(left(ap_gender, 1), '')
	end gender,
	left(ap_ethnicgroupminor, 4) ethnicity,
	null first_language,
	left(ap_aptypedescription, 3) ap_type,
	null onroll,
	null enrol_status,
	null ncy,
	null entry_date,
	null leaving_date,
	ap_fsmeligible,
	null fsm_ever6,
	null fsm_ever6p,
	case ap_senprovision
		when 'S' then 'E'
		when 'A' then 'K'
		when 'P' then 'K'
		else nullif(left(ap_senprovision, 1), '')
	end,
	ap_primarysentype,
	ap_secondarysentype,
	null idaci_rank,
	null idaci_score,
	ap_recordstatus,
	fft_person_id,
	ap_lanumber_geog institution_id,
	row_id = row_number() over (
		partition by fft_person_id, year, ap_lanumber_geog, term_id
		order by (select 1)
		),
	null country,
	null lsoa,
	object_id('npd_i2."<project number>".ap_census_2008_to_2021') source_id
from
	npd_i2."<project number>".ap_census_2008_to_2021
	outer apply (
	select
		year = left(ap_acadyr, 4) + 1,
		yob = ap_yearofbirth,
		mob = ap_monthofbirth
		) x
	left join fft.person_lookup
		on	ap_pupilmatchingrefanonymous collate Latin1_General_BIN = pupil_matching_reference
	-- since we don't know when the record applies, we apply it to every term in
	-- the year; this triples the record count, but AP census is relatively
	-- small and we have found it easier to work with this way.
	outer apply (
	select 1 term_id
	union all select 2
	union all select 3
	) term_id
;

insert fft.census_details
select
	pru_pupilmatchingrefanonymous,
	year,
	term_id,
	case when year - acyob between 0 and 120 then year - acyob - 1 end,
	yob year_of_birth,
	mob month_of_birth,
	case left(pru_gender, 1)
		when 'B' then 'M'
		when 'G' then 'F'
		else nullif(left(pru_gender, 1), '')
	end gender,
	left(pru_ethnicgroupminor, 4) ethnicity,
	left(pru_languagegroupminor, 3) first_language,
	null ap_type,
	case
		-- when the record is split into terms, the on roll flag loses certainty
		-- in Autumn and Summer, but can sometimes be imputed
		when term_id = 1 then nullif(pru_onroll, 0)
		when term_id = 2 then pru_onroll
	end onroll,
	pru_enrolstatus,
	pru_ncyearactual,
	pru_entrydate,
	null leaving_date,
	pru_fsmeligible,
	null fsm_ever6,
	null fsm_ever6p,
	case pru_senprovision
		when 'S' then 'E'
		when 'A' then 'K'
		when 'P' then 'K'
		else nullif(left(pru_senprovision, 1), '')
	end,
	pru_primarysentype,
	pru_secondarysentype,
	pru_idaci_r,
	pru_idaci_s,
	pru_recordstatus,
	fft_person_id,
	isnull(institution_id, pru_la_geog) institution_id,
	row_id = row_number() over (
		partition by fft_person_id, year, isnull(institution_id, pru_la_geog), term_id
		order by case
			when pru_enrolstatus in ('C', 'M') then 1
			when pru_onroll = 1 then 2
			else 3
		end
		),
	case when len(pru_lsoa11) = 9 and isnumeric(right(pru_lsoa11, 8)) = 1 then left(pru_lsoa11, 1) end,
	case when len(pru_lsoa11) = 9 and isnumeric(right(pru_lsoa11, 8)) = 1 then right(pru_lsoa11, 8) end,
	object_id('npd_i2."<project number>".pru_census_2010_to_2013') source_id
from
	npd_i2."<project number>".pru_census_2010_to_2013
	outer apply (
	select
		year = left(pru_academicyear, 4) + 1,
		yob = pru_yearofbirth,
		mob = pru_monthofbirth
		) x
	outer apply (
		select acyob = yob + case when mob >= 9 then 1 else 0 end
		) acyob
	left join fft.person_lookup
		on	pru_pupilmatchingrefanonymous collate Latin1_General_BIN = pupil_matching_reference
	left join fft.laestab_anon s on s.laestab_anon = pru_laestab_anon collate Latin1_General_BIN
	outer apply (
		select 1 term_id, cast(year-1 as varchar(max))+'-10-07' "date"
		union all select 2, cast(year as varchar(max))+'-01-07'
		union all select 3, cast(year as varchar(max))+'-05-07'
		-- if they're already off roll in January, we don't need a May record
		where isnull(pru_onroll, '') <> '0'
		) term_id
where
	-- unlike AP census, PRU census has at least got entry dates so we can use
	-- those to limit the terms the record is related to
	term_id > 1
	or coalesce(nullif(pru_entrydate, ''), term_id."date") <= dateadd(d, 14, term_id."date")
;

drop table fft.wip#sc;
