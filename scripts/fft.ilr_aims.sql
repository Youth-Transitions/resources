
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

/*
PERFORMANCE NOTE

ILR and LEO use a lot of textual identifiers, such as the ILR dataset
identifier and pupil matching reference. Numeric identities are far more
efficient in SQL Server, but we have left the text in for consistency.

Without using a custom numeric identity, it would also be possible improve
performance of scripts making use of the relevant columns by using either:
(a) a binary collation (see the commented code below), though that would
    require adding collation resolution to any expressions involving both them
    and tables (eg source) using default collation; or
(b) a binary rather than character datatype for those columns (eg binary(16)
    rather than char(16)), though some users may be uncomfortable with binary
    or varbinary fields - the change in visual representation changes
    nothing about the data value, but user must cast to a character type for a
    human-readable representation.
Either adjustment would force expressions involving these columns to be
case-sensistive, which might also prove undesireable in some circumstances.

NB: ukprn_anon and upin_anon are provided as a binary type, as per (b); we have
kept them in this format.

NB2: Though the script has been optimised, the source object, which we have no
control over, are (at time of writing) not. As a result, this script can take up
to a full day to run, depending on how many years of data are available to the
project.
*/

-------------------------------------------------------------------------------

-- If re-entrant mode is enabled, the script will attempt to pick up where it
-- was up to in the event of partial completion; it will clear out any existing
-- table and start from scratch otherwise.
declare @reentrant_mode bit = 1;

-------------------------------------------------------------------------------

if schema_id('fft') is null
	exec ('create schema fft;');

if object_id('fft.ilr_aims') is null
begin
create table fft.ilr_aims (
	external_id bigint not null,
	year smallint not null,
	dataset_identifier varchar(4) /* collate Latin1_General_BIN */,
	record_id int,
	upin_anon binary(16),
	ukprn_anon binary(16),
	framework_id smallint,
	pathway_id tinyint,
	standard_id smallint,

	programme_type tinyint,
	aim_id char(8) /* collate Latin1_General_BIN */,
	ldm_1 smallint,
	ldm_2 smallint,
	ldm_3 smallint,
	ldm_4 smallint,

	funding_model tinyint,
	is_funded_aim bit,
	status tinyint,
	is_active bit,
	outcome tinyint,
	grade char(6) /* collate Latin1_General_BIN */,

	completion_status tinyint,

	start_date date,
	end_date date,
	expected_end_date date,
	achievement_date date,

	level2_width real,
	level3_width real,

	is_traineeship bit,
	is_framework_apprenticeship bit,
	is_standard_apprenticeship bit,

	sfl_type tinyint,
	sfl_finetype char(4) /* collate Latin1_General_BIN */,

	ssa_tier1 tinyint,
	ssa_tier2 char(4) /* collate Latin1_General_BIN */,

	notional_nvq_level tinyint,
	notional_level tinyint,
	notional_level_v2 tinyint,
	notional_level_v2_latest tinyint,

	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,
	
	-- These are the original names for fields that FFT has relabelled, allowing
	-- you to use either name (without need to store the data twice).
	recordid as record_id,
	learning_aim_id as aim_id,
	fundmodel as funding_model,
	funded_aim as is_funded_aim,
	a_status as status,
	active as is_active,
	outcome_grade as grade,
	compstatus as completion_status,
	end_date_expected as expected_end_date,
	fl2width as level2_width,
	fl3width as level3_width,
	traineeship as is_traineeship,
	frameworkapp as is_framework_apprenticeship,
	standardapp as is_standard_apprenticeship,
	ssatier1 as ssa_tier1,
	ssatier2 as ssa_tier2,
	notionalnvqlev as notional_nvq_level
	);
create index ix_fft_person_id on fft.ilr_aims(fft_person_id);
end
else if @reentrant_mode = 0
	truncate table fft.ilr_aims;

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
	external_id bigint not null
	);
else truncate table #lookup;

declare @ae_id bigint = 0

while 1 = 1
begin
	insert #lookup
	select top 1000000 with ties
		ae_id,
		external_id
	from
		LEO_i2."<project number>".education_records_lookup lk
		inner join LILR_i2."<project number>".learners lr
			on	lk.recordid = lr.recordid
	where
		ae_id > @ae_id
	group by
		ae_id,
		external_id
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
	null pupil_matching_reference,
	external_id,
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
set ilr_external_id = lk.external_id
from
	fft.person_lookup pl
	inner join (
	select
		ae_id,
		external_id = min(external_id)
	from
		#lookup
	group by
		ae_id
	) lk
		on	pl.ae_id = lk.ae_id
where
	ilr_external_id is null
	and multiplex = 1
;
insert fft.person_lookup
select
	fft_person_id,
	(select max(multiplex) from fft.person_lookup where fft_person_id = pl.fft_person_id) + r multiplex,
	null ae_id,
	null pupil_matching_reference,
	external_id,
	null edukey
from
	(
	select
		lk.external_id,
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
				ilr_external_id,
				ae_id = min(ae_id) over (partition by fft_person_id)
			from
				fft.person_lookup
			) _
		where
			ilr_external_id = lk.external_id
			and ae_id = lk.ae_id
		)
	group by
		lk.external_id
	) pl
;
insert fft.person_lookup
select
	(select max(fft_person_id) from fft.person_lookup)
	+ row_number() over (order by (select 1)),
	1 multiplex,
	null ae_id,
	null pupil_matching_reference,
	external_id,
	null edukey
from
	(
	select distinct external_id
	from LILR_i2."<project number>".learners
	where
		external_id not in (
		select ilr_external_id
		from fft.person_lookup
		where ilr_external_id is not null
		)
	) _
;

drop table #lookup;

--------------------------------------------------------------------------------
-- main load start
--------------------------------------------------------------------------------

declare
	@year smallint = 2002,
	@max_year smallint
;

select top 1
	@year = year + 1
from fft.ilr_aims
order by year desc
;

select
	@max_year = max(right(academicyear, 4)) + 1
from
	LILR_i2."<project number>".learners
;

-- At time of writing, LEO ILR requires batch loading due to the lack of
-- indexing on either the LEO views or the underlying tables. We use year
-- as the batching index.
while @year < @max_year
begin
	insert fft.ilr_aims
	select
		src.external_id,
		@year,
		src.dataset_identifier,
		src.recordid,
		nullif(src.upin_anon, 0x),
		nullif(src.ukprn_anon, 0x),
		nullif(src.framework_id, -1),
		nullif(src.pathway_id, -1),
		nullif(src.standard_id, -1),
		nullif(src.programme_type, -1),
		src.learning_aim_id,
		src.LDM_1,
		src.LDM_2,
		src.LDM_3,
		src.LDM_4,
		nullif(src.fundmodel, -1),
		nullif(src.funded_aim, -1),
		abs(nullif(src.a_status, -1)),
		src.active,
		nullif(src.outcome, -1),
		nullif(src.outcome_grade, ''),
		nullif(src.compstatus, -1),
		src.start_date,
		src.end_date,
		src.end_date_expected,
		src.achievement_date,
		src.fl2width,
		src.fl3width,
		nullif(src.traineeship, -1),
		nullif(src.frameworkapp, -1),
		nullif(src.standardapp, -1),
		nullif(src.sfl_type, -1),
		case when len(src.sfl_finetype) < 5 then nullif(src.sfl_finetype, '') end,
		nullif(src.ssatier1+0e, -1),
		src.ssatier2+0e,
		nullif(src.notionalnvqlev, -1),
		nullif(src.notional_level, -1),
		nullif(src.notional_level_v2, -1),
		nullif(src.notional_level_v2_latest, -1),

		fft_person_id
		-- the remaining columns are calculated; it is not necessary (or
		-- correct) to load data into them.
	from
		-- using a subquery to select the records of interest first since the
		-- join to lookup can cause performance problems when used in
		-- combination with the LEO views.
		(
		select *
		from
			LILR_i2."<project number>".aims
		where
			right(academicyear, 4) = @year
			and external_id is not null
		) src
		-- left join used here in an effort to overcome the execution planner's
		-- inability to estimate resulting row count without statistics
		-- (indexes).
		left join fft.person_lookup
			on	ilr_external_id = src.external_id
	where
		-- if the person id is not set then the aims data have come without a
		-- learner and we are probably safe to ignore it.
		fft_person_id is not null
	;

	set @year += 1;
end
