
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

-- Note: for space efficiency reasons we do not include PMR in the normalized
-- data table, though it is included in the fft.attendance_3term view.

if schema_id('fft') is null
	exec ('create schema fft;');

--drop table fft.attendance;
if object_id('fft.attendance') is null
begin
create table fft.attendance (
	year smallint not null,
	term_id tinyint not null,
	possible_sessions smallint not null,
	authorised_absence smallint not null,
	unauthorised_absence smallint not null,
	
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
	
	primary key (
		fft_person_id,
		year,
		term_id,
		institution_id,
		row_id
		)
	);
alter table fft.attendance rebuild partition = all with (data_compression = page);
end
else truncate table fft.attendance;

if object_id('fft.attendance_3term') is not null
	drop view fft.attendance_3term;

go
create view fft.attendance_3term
as
select
	max(pupil_matching_reference) collate database_default pupil_matching_reference,
	year,
	possible_sessions_autumn = sum(case term_id when 1 then possible_sessions end),
	authorised_absence_autumn = sum(case term_id when 1 then authorised_absence end),
	unauthorised_absence_autumn = sum(case term_id when 1 then unauthorised_absence end),
	possible_sessions_spring = sum(case term_id when 2 then possible_sessions end),
	authorised_absence_spring = sum(case term_id when 2 then authorised_absence end),
	unauthorised_absence_spring = sum(case term_id when 2 then unauthorised_absence end),
	possible_sessions_summer = sum(case term_id when 3 then possible_sessions end),
	authorised_absence_summer = sum(case term_id when 3 then authorised_absence end),
	unauthorised_absence_summer = sum(case term_id when 3 then unauthorised_absence end),
	total_possible_sessions = sum(possible_sessions),
	total_authorised_absence = sum(authorised_absence),
	total_unauthorised_absence = sum(unauthorised_absence),
	
	a.fft_person_id,
	institution_id,
	source_id = max(source_id),
	
	-- since there can be multiple records for a single person, school and term
	-- combination, this can be used to identify potential duplicate record
	-- issues, where the sums above may be double-counting.
	max_row_id = max(row_id),
	
	academic_year = cast(year-1 as varchar(16))
		+ '/' + right(cast(year as varchar(16)), 2),
	
	PupilMatchingRefAnonymous = max(pupil_matching_reference) collate database_default
from
	fft.attendance a
	left join fft.person_lookup p on a.fft_person_id = p.fft_person_id
group by
	a.fft_person_id,
	institution_id,
	year
;

go

if object_id('fft.wip#attend') is null
begin
create table fft.wip#attend (
	year smallint not null,
	term_id tinyint not null,
	possible_sessions smallint not null,
	authorised_absence smallint not null,
	unauthorised_absence smallint not null,
	pmr varchar(30) collate Latin1_General_BIN not null,
	laestab_anon varchar(30) collate Latin1_General_BIN not null,
	source_id int not null
	);
alter table fft.wip#attend rebuild partition = all with (data_compression = page);
end
else truncate table fft.wip#attend;

--------------------------------------------------------------------------------
-- compile sources
--------------------------------------------------------------------------------

if object_id('npd_i2."<project number>".Absence_2006_3term') is not null
insert fft.wip#attend
select
	2006 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab06,
	LAEstab_ANON_ab06,
	object_id('npd_i2."<project number>".Absence_2006_3term')
from
	npd_i2."<project number>".Absence_2006_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab06 sessions_possible,
		AuthorisedAbsence_Autumn_ab06 authorised,
		UnauthorisedAbsence_Autumn_ab06 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab06,
		AuthorisedAbsence_Spring_ab06,
		UnauthorisedAbsence_Spring_ab06
	union all select
		3,
		SessionsPossible_Summer_ab06,
		AuthorisedAbsence_Summer_ab06,
		UnauthorisedAbsence_Summer_ab06
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2007_3term') is not null
insert fft.wip#attend
select
	2007 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab07,
	LAEstab_ANON_ab07,
	object_id('npd_i2."<project number>".Absence_2007_3term')
from
	npd_i2."<project number>".Absence_2007_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab07 sessions_possible,
		AuthorisedAbsence_Autumn_ab07 authorised,
		UnauthorisedAbsence_Autumn_ab07 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab07,
		AuthorisedAbsence_Spring_ab07,
		UnauthorisedAbsence_Spring_ab07
	union all select
		3,
		SessionsPossible_Summer_ab07,
		AuthorisedAbsence_Summer_ab07,
		UnauthorisedAbsence_Summer_ab07
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2008_3term') is not null
insert fft.wip#attend
select
	2008 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab08,
	LAEstab_ANON_ab08,
	object_id('npd_i2."<project number>".Absence_2008_3term')
from
	npd_i2."<project number>".Absence_2008_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab08 sessions_possible,
		AuthorisedAbsence_Autumn_ab08 authorised,
		UnauthorisedAbsence_Autumn_ab08 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab08,
		AuthorisedAbsence_Spring_ab08,
		UnauthorisedAbsence_Spring_ab08
	union all select
		3,
		SessionsPossible_Summer_ab08,
		AuthorisedAbsence_Summer_ab08,
		UnauthorisedAbsence_Summer_ab08
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2009_3term') is not null
insert fft.wip#attend
select
	2009 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab09,
	LAEstab_ANON_ab09,
	object_id('npd_i2."<project number>".Absence_2009_3term')
from
	npd_i2."<project number>".Absence_2009_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab09 sessions_possible,
		AuthorisedAbsence_Autumn_ab09 authorised,
		UnauthorisedAbsence_Autumn_ab09 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab09,
		AuthorisedAbsence_Spring_ab09,
		UnauthorisedAbsence_Spring_ab09
	union all select
		3,
		SessionsPossible_Summer_ab09,
		AuthorisedAbsence_Summer_ab09,
		UnauthorisedAbsence_Summer_ab09
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2010_3term') is not null
insert fft.wip#attend
select
	2010 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab10,
	LAEstab_ANON_ab10,
	object_id('npd_i2."<project number>".Absence_2010_3term')
from
	npd_i2."<project number>".Absence_2010_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab10 sessions_possible,
		AuthorisedAbsence_Autumn_ab10 authorised,
		UnauthorisedAbsence_Autumn_ab10 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab10,
		AuthorisedAbsence_Spring_ab10,
		UnauthorisedAbsence_Spring_ab10
	union all select
		3,
		SessionsPossible_Summer_ab10,
		AuthorisedAbsence_Summer_ab10,
		UnauthorisedAbsence_Summer_ab10
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2011_3term') is not null
insert fft.wip#attend
select
	2011 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab11,
	LAEstab_ANON_ab11,
	object_id('npd_i2."<project number>".Absence_2011_3term')
from
	npd_i2."<project number>".Absence_2011_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab11 sessions_possible,
		AuthorisedAbsence_Autumn_ab11 authorised,
		UnauthorisedAbsence_Autumn_ab11 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab11,
		AuthorisedAbsence_Spring_ab11,
		UnauthorisedAbsence_Spring_ab11
	union all select
		3,
		SessionsPossible_Summer_ab11,
		AuthorisedAbsence_Summer_ab11,
		UnauthorisedAbsence_Summer_ab11
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2012_3term') is not null
insert fft.wip#attend
select
	2012 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab12,
	LAEstab_ANON_ab12,
	object_id('npd_i2."<project number>".Absence_2012_3term')
from
	npd_i2."<project number>".Absence_2012_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab12 sessions_possible,
		AuthorisedAbsence_Autumn_ab12 authorised,
		UnauthorisedAbsence_Autumn_ab12 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab12,
		AuthorisedAbsence_Spring_ab12,
		UnauthorisedAbsence_Spring_ab12
	union all select
		3,
		SessionsPossible_Summer_ab12,
		AuthorisedAbsence_Summer_ab12,
		UnauthorisedAbsence_Summer_ab12
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2013_3term') is not null
insert fft.wip#attend
select
	2013 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab13,
	LAEstab_ANON_ab13,
	object_id('npd_i2."<project number>".Absence_2013_3term')
from
	npd_i2."<project number>".Absence_2013_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab13 sessions_possible,
		AuthorisedAbsence_Autumn_ab13 authorised,
		UnauthorisedAbsence_Autumn_ab13 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab13,
		AuthorisedAbsence_Spring_ab13,
		UnauthorisedAbsence_Spring_ab13
	union all select
		3,
		SessionsPossible_Summer_ab13,
		AuthorisedAbsence_Summer_ab13,
		UnauthorisedAbsence_Summer_ab13
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2014_3term') is not null
insert fft.wip#attend
select
	2014 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab14,
	LAEstab_ANON_ab14,
	object_id('npd_i2."<project number>".Absence_2014_3term')
from
	npd_i2."<project number>".Absence_2014_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab14 sessions_possible,
		AuthorisedAbsence_Autumn_ab14 authorised,
		UnauthorisedAbsence_Autumn_ab14 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab14,
		AuthorisedAbsence_Spring_ab14,
		UnauthorisedAbsence_Spring_ab14
	union all select
		3,
		SessionsPossible_Summer_ab14,
		AuthorisedAbsence_Summer_ab14,
		UnauthorisedAbsence_Summer_ab14
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2015_3term') is not null
insert fft.wip#attend
select
	2015 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab15,
	LAEstab_ANON_ab15,
	object_id('npd_i2."<project number>".Absence_2015_3term')
from
	npd_i2."<project number>".Absence_2015_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab15 sessions_possible,
		AuthorisedAbsence_Autumn_ab15 authorised,
		UnauthorisedAbsence_Autumn_ab15 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab15,
		AuthorisedAbsence_Spring_ab15,
		UnauthorisedAbsence_Spring_ab15
	union all select
		3,
		SessionsPossible_Summer_ab15,
		AuthorisedAbsence_Summer_ab15,
		UnauthorisedAbsence_Summer_ab15
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2016_3term') is not null
insert fft.wip#attend
select
	2016 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab16,
	LAEstab_ANON_ab16,
	object_id('npd_i2."<project number>".Absence_2016_3term')
from
	npd_i2."<project number>".Absence_2016_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab16 sessions_possible,
		AuthorisedAbsence_Autumn_ab16 authorised,
		UnauthorisedAbsence_Autumn_ab16 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab16,
		AuthorisedAbsence_Spring_ab16,
		UnauthorisedAbsence_Spring_ab16
	union all select
		3,
		SessionsPossible_Summer_ab16,
		AuthorisedAbsence_Summer_ab16,
		UnauthorisedAbsence_Summer_ab16
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2017_3term') is not null
insert fft.wip#attend
select
	2017 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab17,
	LAEstab_ANON_ab17,
	object_id('npd_i2."<project number>".Absence_2017_3term')
from
	npd_i2."<project number>".Absence_2017_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab17 sessions_possible,
		AuthorisedAbsence_Autumn_ab17 authorised,
		UnauthorisedAbsence_Autumn_ab17 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab17,
		AuthorisedAbsence_Spring_ab17,
		UnauthorisedAbsence_Spring_ab17
	union all select
		3,
		SessionsPossible_Summer_ab17,
		AuthorisedAbsence_Summer_ab17,
		UnauthorisedAbsence_Summer_ab17
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2018_3term') is not null
insert fft.wip#attend
select
	2018 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab18,
	LAEstab_ANON_ab18,
	object_id('npd_i2."<project number>".Absence_2018_3term')
from
	npd_i2."<project number>".Absence_2018_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab18 sessions_possible,
		AuthorisedAbsence_Autumn_ab18 authorised,
		UnauthorisedAbsence_Autumn_ab18 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab18,
		AuthorisedAbsence_Spring_ab18,
		UnauthorisedAbsence_Spring_ab18
	union all select
		3,
		SessionsPossible_Summer_ab18,
		AuthorisedAbsence_Summer_ab18,
		UnauthorisedAbsence_Summer_ab18
	) x
where
	sessions_possible > 0
;

if object_id('npd_i2."<project number>".Absence_2019_3term') is not null
insert fft.wip#attend
select
	2019 year,
	term_id,
	sessions_possible,
	authorised,
	unauthorised,
	PupilMatchingRefAnonymous_ab19,
	LAEstab_ANON_ab19,
	object_id('npd_i2."<project number>".Absence_2019_3term')
from
	npd_i2."<project number>".Absence_2019_3term
	outer apply (
	select
		1 term_id,
		SessionsPossible_Autumn_ab19 sessions_possible,
		AuthorisedAbsence_Autumn_ab19 authorised,
		UnauthorisedAbsence_Autumn_ab19 unauthorised
	union all select
		2,
		SessionsPossible_Spring_ab19,
		AuthorisedAbsence_Spring_ab19,
		UnauthorisedAbsence_Spring_ab19
	union all select
		3,
		SessionsPossible_Summer_ab19,
		AuthorisedAbsence_Summer_ab19,
		UnauthorisedAbsence_Summer_ab19
	) x
where
	sessions_possible > 0
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
	from fft.wip#attend
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
	fft.wip#attend
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

insert fft.attendance
select
	year,
	term_id,
	possible_sessions,
	authorised_absence,
	unauthorised_absence,
	fft_person_id,
	institution_id,
	row_id = row_number() over (
		partition by fft_person_id, year, term_id, institution_id
		order by possible_sessions desc
		),
	source_id
from
	fft.wip#attend a
	left join fft.person_lookup p
		on	p.pupil_matching_reference = a.pupil_matching_reference
	left join fft.laestab_anon s
		on	s.laestab_anon = a.laestab_anon
;

drop table fft.wip#attend;
