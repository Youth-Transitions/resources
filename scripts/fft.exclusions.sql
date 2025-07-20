
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

if schema_id('fft') is null
	exec ('create schema fft;');

if object_id('fft.exclusions') is null
begin
create table fft.exclusions (
	pupil_matching_reference char(18) /* collate Latin1_General_BIN */ not null,
	year smallint not null,
	start_date date,
	number_of_sessions smallint,
	enrolment_status char(1),
	is_permanent bit not null,
	is_lunchtime bit not null,
	permanent_duplicate bit,
	reason char(2),
	
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
	
	-- The source_id is the object_id of the source; it can be used for example
	-- in error investigation and resolution to determine where a given record
	-- came from.
	source_id int not null,
	
	-- utilities
	academic_year as cast(year-1 as varchar(16))
		+ '/' + right(cast(year as varchar(16)), 2),
	
	primary key (fft_person_id, year, institution_id, row_id)
	);
alter table fft.exclusions rebuild partition = all with (data_compression = page);
end
else truncate table fft.exclusions;

if object_id('fft.wip#exc') is null
begin
create table fft.wip#exc (
	pmr varchar(30) collate Latin1_General_BIN not null,
	year smallint not null,
	start_date date,
	number_of_sessions smallint,
	enrolment_status char(1),
	is_permanent bit not null,
	is_lunchtime bit not null,
	permanent_duplicate bit,
	reason char(2),
	laestab_anon varchar(30) collate Latin1_General_BIN not null,
	source_id int not null
	);
alter table fft.wip#exc rebuild partition = all with (data_compression = page);
end
else truncate table fft.wip#exc;

--------------------------------------------------------------------------------
-- compile sources
--------------------------------------------------------------------------------

if object_id('npd_i2."<project number>".exclusions_2003') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex03,
	2003,
	startdate_ex03,
	null sessions,
	null enrol_status,
	case 'P' when permanentexclusionind_ex03 then 1 else 0 end permanent,
	0 lunchtime,
	null duplicate,
	null reason,
	laestab_anon_ex03,
	object_id('npd_i2."<project number>".exclusions_2003')
from
	npd_i2."<project number>".exclusions_2003
;
if object_id('npd_i2."<project number>".exclusions_2004') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex04,
	2004,
	startdate_ex04,
	null sessions,
	null enrol_status,
	case 'P' when permanentexclusionind_ex04 then 1 else 0 end permanent,
	0 lunchtime,
	null duplicate,
	null reason,
	laestab_anon_ex04,
	object_id('npd_i2."<project number>".exclusions_2004')
from
	npd_i2."<project number>".exclusions_2004
;
if object_id('npd_i2."<project number>".exclusions_2005') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex05,
	2005,
	startdate_ex05,
	null sessions,
	null enrol_status,
	1 permanent, -- 2005 only contains permanent exclusions
	0 lunchtime,
	null duplicate,
	null reason,
	laestab_anon_ex05,
	object_id('npd_i2."<project number>".exclusions_2005')
from
	npd_i2."<project number>".exclusions_2005
;
if object_id('npd_i2."<project number>".exclusions_table_1_2006') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex06,
	2006,
	startdate_ex06,
	sessions_ex06,
	enrolstatus_ex06,
	case 'PERM' when category_ex06 then 1 else 0 end permanent,
	case 'LNCH' when category_ex06 then 1 else 0 end lunchtime,
	perm_duplicate_ex06,
	reason_ex06,
	laestab_anon_ex06,
	object_id('npd_i2."<project number>".exclusions_table_1_2006')
from
	npd_i2."<project number>".exclusions_table_1_2006
;
if object_id('npd_i2."<project number>".exclusions_table_1_2007') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex07,
	2007,
	startdate_ex07,
	sessions_ex07,
	enrolstatus_ex07,
	case 'PERM' when category_ex07 then 1 else 0 end permanent,
	case 'LNCH' when category_ex07 then 1 else 0 end lunchtime,
	perm_duplicate_ex07,
	reason_ex07,
	laestab_anon_ex07,
	object_id('npd_i2."<project number>".exclusions_table_1_2007')
from
	npd_i2."<project number>".exclusions_table_1_2007
;
if object_id('npd_i2."<project number>".exclusions_table_1_2008') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex08,
	2008,
	startdate_ex08,
	sessions_ex08,
	enrolstatus_ex08,
	case 'PERM' when category_ex08 then 1 else 0 end permanent,
	case 'LNCH' when category_ex08 then 1 else 0 end lunchtime,
	perm_duplicate_ex08,
	reason_ex08,
	laestab_anon_ex08,
	object_id('npd_i2."<project number>".exclusions_table_1_2008')
from
	npd_i2."<project number>".exclusions_table_1_2008
;
if object_id('npd_i2."<project number>".exclusions_table_1_2009') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex09,
	2009,
	startdate_ex09,
	sessions_ex09,
	enrolstatus_ex09,
	case 'PERM' when category_ex09 then 1 else 0 end permanent,
	case 'LNCH' when category_ex09 then 1 else 0 end lunchtime,
	perm_duplicate_ex09,
	reason_ex09,
	laestab_anon_ex09,
	object_id('npd_i2."<project number>".exclusions_table_1_2009')
from
	npd_i2."<project number>".exclusions_table_1_2009
;
if object_id('npd_i2."<project number>".exclusions_table_1_2010') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex10,
	2010,
	startdate_ex10,
	sessions_ex10,
	enrolstatus_ex10,
	case 'PERM' when category_ex10 then 1 else 0 end permanent,
	case 'LNCH' when category_ex10 then 1 else 0 end lunchtime,
	perm_duplicate_ex10,
	reason_ex10,
	laestab_anon_ex10,
	object_id('npd_i2."<project number>".exclusions_table_1_2010')
from
	npd_i2."<project number>".exclusions_table_1_2010
;
if object_id('npd_i2."<project number>".exclusions_table_1_2011') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex11,
	2011,
	startdate_ex11,
	sessions_ex11,
	enrolstatus_ex11,
	case 'PERM' when category_ex11 then 1 else 0 end permanent,
	case 'LNCH' when category_ex11 then 1 else 0 end lunchtime,
	perm_duplicate_ex11,
	reason_ex11,
	laestab_anon_ex11,
	object_id('npd_i2."<project number>".exclusions_table_1_2011')
from
	npd_i2."<project number>".exclusions_table_1_2011
;
if object_id('npd_i2."<project number>".exclusions_table_1_2012') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex12,
	2012,
	startdate_ex12,
	sessions_ex12,
	enrolstatus_ex12,
	case 'PERM' when category_ex12 then 1 else 0 end permanent,
	case 'LNCH' when category_ex12 then 1 else 0 end lunchtime,
	perm_duplicate_ex12,
	reason_ex12,
	laestab_anon_ex12,
	object_id('npd_i2."<project number>".exclusions_table_1_2012')
from
	npd_i2."<project number>".exclusions_table_1_2012
;
if object_id('npd_i2."<project number>".exclusions_table_1_2013') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex13,
	2013,
	startdate_ex13,
	sessions_ex13,
	enrolstatus_ex13,
	case 'PERM' when category_ex13 then 1 else 0 end permanent,
	case 'LNCH' when category_ex13 then 1 else 0 end lunchtime,
	perm_duplicate_ex13,
	reason_ex13,
	laestab_anon_ex13,
	object_id('npd_i2."<project number>".exclusions_table_1_2013')
from
	npd_i2."<project number>".exclusions_table_1_2013
;
if object_id('npd_i2."<project number>".exclusions_table_1_2014') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex14,
	2014,
	startdate_ex14,
	sessions_ex14,
	enrolstatus_ex14,
	case 'PERM' when category_ex14 then 1 else 0 end permanent,
	case 'LNCH' when category_ex14 then 1 else 0 end lunchtime,
	perm_duplicate_ex14,
	reason_ex14,
	laestab_anon_ex14,
	object_id('npd_i2."<project number>".exclusions_table_1_2014')
from
	npd_i2."<project number>".exclusions_table_1_2014
;
if object_id('npd_i2."<project number>".exclusions_table_1_2015') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex15,
	2015,
	startdate_ex15,
	sessions_ex15,
	enrolstatus_ex15,
	case 'PERM' when category_ex15 then 1 else 0 end permanent,
	case 'LNCH' when category_ex15 then 1 else 0 end lunchtime,
	perm_duplicate_ex15,
	reason_ex15,
	laestab_anon_ex15,
	object_id('npd_i2."<project number>".exclusions_table_1_2015')
from
	npd_i2."<project number>".exclusions_table_1_2015
;
if object_id('npd_i2."<project number>".exclusions_table_1_2016') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex16,
	2016,
	startdate_ex16,
	sessions_ex16,
	enrolstatus_ex16,
	case 'PERM' when category_ex16 then 1 else 0 end permanent,
	case 'LNCH' when category_ex16 then 1 else 0 end lunchtime,
	perm_duplicate_ex16,
	reason_ex16,
	laestab_anon_ex16,
	object_id('npd_i2."<project number>".exclusions_table_1_2016')
from
	npd_i2."<project number>".exclusions_table_1_2016
;
if object_id('npd_i2."<project number>".exclusions_table_1_2017') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex17,
	2017,
	startdate_ex17,
	sessions_ex17,
	enrolstatus_ex17,
	case 'PERM' when category_ex17 then 1 else 0 end permanent,
	case 'LNCH' when category_ex17 then 1 else 0 end lunchtime,
	perm_duplicate_ex17,
	reason_ex17,
	laestab_anon_ex17,
	object_id('npd_i2."<project number>".exclusions_table_1_2017')
from
	npd_i2."<project number>".exclusions_table_1_2017
;
if object_id('npd_i2."<project number>".exclusions_table_1_2018') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex18,
	2018,
	startdate_ex18,
	sessions_ex18,
	enrolstatus_ex18,
	case 'PERM' when category_ex18 then 1 else 0 end permanent,
	case 'LNCH' when category_ex18 then 1 else 0 end lunchtime,
	perm_duplicate_ex18,
	reason_ex18,
	laestab_anon_ex18,
	object_id('npd_i2."<project number>".exclusions_table_1_2018')
from
	npd_i2."<project number>".exclusions_table_1_2018
;
if object_id('npd_i2."<project number>".exclusions_table_1_2019') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex19,
	2019,
	startdate_ex19,
	sessions_ex19,
	enrolstatus_ex19,
	case 'PERM' when category_ex19 then 1 else 0 end permanent,
	case 'LNCH' when category_ex19 then 1 else 0 end lunchtime,
	perm_duplicate_ex19,
	reason_ex19,
	laestab_anon_ex19,
	object_id('npd_i2."<project number>".exclusions_table_1_2019')
from
	npd_i2."<project number>".exclusions_table_1_2019
;
if object_id('npd_i2."<project number>".exclusions_table_1_2020') is not null
insert fft.wip#exc
select
	pupilmatchingrefanonymous_ex20,
	2020,
	startdate_ex20,
	sessions_ex20,
	enrolstatus_ex20,
	case 'PERM' when category_ex20 then 1 else 0 end permanent,
	case 'LNCH' when category_ex20 then 1 else 0 end lunchtime,
	perm_duplicate_ex20,
	reason_ex20,
	laestab_anon_ex20,
	object_id('npd_i2."<project number>".exclusions_table_1_2020')
from
	npd_i2."<project number>".exclusions_table_1_2020
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
	from fft.wip#exc
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
	fft.wip#exc
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
-- main load
--------------------------------------------------------------------------------

insert fft.exclusions
select
	pmr,
	year,
	start_date,
	number_of_sessions,
	enrolment_status,
	is_permanent,
	is_lunchtime,
	permanent_duplicate,
	reason,
	fft_person_id,
	institution_id,
	row_id = row_number() over (
		partition by fft_person_id, year, institution_id
		order by (select 1)
		),
	source_id
from
	fft.wip#exc e
	left join fft.person_lookup p
		on	p.pupil_matching_reference = e.pmr
	left join fft.laestab_anon s
		on	s.laestab_anon = e.laestab_anon
;

drop table fft.wip#exc;
