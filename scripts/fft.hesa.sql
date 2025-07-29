
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

-- In our projects, we are usually interested in when an individual was engaged
-- in high learning, rather than, for example, the instituion or campus. Since
-- the pseudonymisation of UKPRN renders this unhelpful, we have loaded only a
-- limited selection of columns, but we are aware this may not be ideal in all
-- use cases.

if object_id('fft.hesa') is null
create table fft.hesa (
	pupil_matching_reference char(18) /* collate Latin1_General_BIN */ not null,
	year smallint not null,
	start_date date,
	end_date date,
	year_of_program tinyint,
	year_of_study tinyint,

	xmode tinyint,
	xpqual bit,
	xlev6 char(1),
	xqlev6 char(1),
	xqobtn char(3),
	xpsr tinyint,

	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,
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
	
	-- These are the original names for fields that FFT has relabelled, allowing
	-- you to use either name (without need to store the data twice).
	ComDate as start_date,
	EndDate as end_date,
	YearPrg as year_of_program,
	YearStu as year_of_study,
	xmode01 as xmode,
	xpqual01 as xpqual,
	xlev601 as xlev6,
	xqlev601 as xqlev6,
	xqobtn01 as xqobtn,
	xpsr01 as xpsr,
	
	primary key(fft_person_id, year, row_id)
	);
else truncate table fft.hesa;

-- We could use a temporary table to do this instead, but tempdb has been known
-- to run out of space on the SRS servers when too many users are making use of
-- it concurrently.
if object_id('fft.wip#hesa') is null
begin
create table fft.wip#hesa (
	pmr varchar(30) collate Latin1_General_BIN not null,
	year smallint not null,
	start_date date,
	end_date date,
	year_of_program tinyint,
	year_of_study tinyint,
	xmode tinyint,
	xpqual bit,
	xlev6 char(1),
	xqlev6 char(1),
	xqobtn char(3),
	xpsr tinyint,
	source_id int not null,
	);
alter table fft.wip#hesa rebuild partition = all with (data_compression = page);
create index ix_pmr on fft.wip#hesa (pmr);
end
else truncate table fft.wip#hesa;

--------------------------------------------------------------------------------
-- compile sources
--------------------------------------------------------------------------------

if object_id('hesa_i2."<project number>".hesa_2005') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2005 year,
	he_comdate start_date,
	he_dateleft end_date,
	case 1 when isnumeric(he_yearprg) then he_yearprg end year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2005')
from
	hesa_i2."<project number>".hesa_2005 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2006') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2006 year,
	he_comdate start_date,
	he_dateleft end_date,
	case 1 when isnumeric(he_yearprg) then he_yearprg end year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2006')
from
	hesa_i2."<project number>".hesa_2006 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2007') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2007 year,
	he_comdate start_date,
	he_dateleft end_date,
	case 1 when isnumeric(he_yearprg) then he_yearprg end year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2007')
from
	hesa_i2."<project number>".hesa_2007 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2008') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2008 year,
	he_comdate start_date,
	he_enddate end_date,
	case 1 when isnumeric(he_yearprg) then he_yearprg end year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2008')
from
	hesa_i2."<project number>".hesa_2008 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2009') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2009 year,
	he_comdate start_date,
	he_enddate end_date,
	case 1 when isnumeric(he_yearprg) then he_yearprg end year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2009')
from
	hesa_i2."<project number>".hesa_2009 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2010') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2010 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2010')
from
	hesa_i2."<project number>".hesa_2010 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2011') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2011 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2011')
from
	hesa_i2."<project number>".hesa_2011 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2012') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2012 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2012')
from
	hesa_i2."<project number>".hesa_2012 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2013') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2013 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2013')
from
	hesa_i2."<project number>".hesa_2013 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2014') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2014 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2014')
from
	hesa_i2."<project number>".hesa_2014 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2015') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2015 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2015')
from
	hesa_i2."<project number>".hesa_2015 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2016') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2016 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2016')
from
	hesa_i2."<project number>".hesa_2016 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2017') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2017 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2017')
from
	hesa_i2."<project number>".hesa_2017 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2018') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2018 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2018')
from
	hesa_i2."<project number>".hesa_2018 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2019') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2019 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2019')
from
	hesa_i2."<project number>".hesa_2019 src
where
	he_pupilmatchingrefanonymous <> ''
;

if object_id('hesa_i2."<project number>".hesa_2020') is not null
insert fft.wip#hesa
select
	he_pupilmatchingrefanonymous,
	2020 year,
	he_comdate start_date,
	he_enddate end_date,
	he_yearprg year_of_program,
	he_yearstu year_of_study,

	he_xmode01,
	he_xpqual01,
	he_xlev601,
	he_xqlev601,
	he_xqobtn01,
	he_xpsr01,

	source_id = object_id('hesa_i2."<project number>".hesa_2020')
from
	hesa_i2."<project number>".hesa_2020 src
where
	he_pupilmatchingrefanonymous <> ''
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
	ilr_external_int bigint,
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
			pupil_matching_reference = pmr
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
	from fft.wip#hesa
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
-- main load start
--------------------------------------------------------------------------------

insert fft.hesa
select
	pmr,
	year,
	start_date,
	end_date,
	year_of_program,
	year_of_study,
	xmode,
	xpqual,
	xlev6,
	xqlev6,
	xqobtn,
	xpsr,
	fft_person_id,
	row_number() over (partition by fft_person_id, year order by (select 1)),
	source_id
from
	fft.wip#hesa
	left join fft.person_lookup
		on	pmr = pupil_matching_reference
;

drop table fft.wip#hesa;
