
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

if object_id('fft.plams') is null
create table fft.plams (
	year smallint not null,
	start_date date,
	end_date date,
	fuzzy_end_date bit,
	qan char(8),
	disc_code char(4),
	sublevno smallint,
	grade varchar(5),
	traineeship bit,
	
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

	primary key (
		fft_person_id,
		qan,
		year,
		institution_id,
		row_id
		)
	);
else truncate table fft.plams;

if object_id('fft.wip#plams') is null
create table fft.wip#plams (
	pmr varchar(30) collate Latin1_General_BIN not null,
	laestab_anon varchar(20) not null,
	year smallint not null,
	start_date date,
	end_date date,
	fuzzy_end_date bit,
	qan char(8),
	disc_code char(4),
	sublevno smallint,
	grade varchar(5),
	traineeship bit,
	source_id int not null
	);
else truncate table fft.wip#plams;

--------------------------------------------------------------------------------
-- compile sources
--------------------------------------------------------------------------------

if object_id('NPD_i2."<project number>".PLAMS_Amended_2008') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2008,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2008')
from
	NPD_i2."<project number>".PLAMS_Amended_2008
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2009') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2009,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2009')
from
	NPD_i2."<project number>".PLAMS_Amended_2009
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2010') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2010,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2010')
from
	NPD_i2."<project number>".PLAMS_Amended_2010
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2011') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2011,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2011')
from
	NPD_i2."<project number>".PLAMS_Amended_2011
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2012') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2012,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	-- some of these columns have been missing in some projects...
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2012')
from
	NPD_i2."<project number>".PLAMS_Amended_2012
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2013') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2013,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2013')
from
	NPD_i2."<project number>".PLAMS_Amended_2013
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2014') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2014,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2014')
from
	NPD_i2."<project number>".PLAMS_Amended_2014
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2015') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2015,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qan, pl_qan_att),
	coalesce(nullif(pl_disc_code, ''), nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2015')
from
	NPD_i2."<project number>".PLAMS_Amended_2015
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2016') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2016,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2016')
from
	NPD_i2."<project number>".PLAMS_Amended_2016
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2017') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2017,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2017')
from
	NPD_i2."<project number>".PLAMS_Amended_2017
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2018') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2018,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2018')
from
	NPD_i2."<project number>".PLAMS_Amended_2018
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2019') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2019,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2019')
from
	NPD_i2."<project number>".PLAMS_Amended_2019
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2020') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2020,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2020')
from
	NPD_i2."<project number>".PLAMS_Amended_2020
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2021') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2021,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2021')
from
	NPD_i2."<project number>".PLAMS_Amended_2021
;
if object_id('NPD_i2."<project number>".PLAMS_Amended_2022') is not null
insert fft.wip#plams
select
	pl_PupilMatchingRefAnonymous,
	pl_laestab_anon,
	2022,
	pl_learningstartdate,
	isnull(nullif(pl_learningactualenddate, ''), nullif(pl_learningplannedenddate, '')),
	case
		when pl_learningactualenddate <> '' then 0
		when pl_learningplannedenddate <> '' then 1
		else 0
	end,
	isnull(pl_qn, pl_qan_att),
	coalesce(nullif(pl_disc_code_att, ''), nullif(pl_disc_code_ref, '')),
	coalesce(nullif(pl_sublevno_att, ''), nullif(pl_sublevno_ref, '')),
	nullif(pl_grade_att, ''),
	case when pl_traineeship in ('0', '1') then pl_traineeship end,
	object_id('NPD_i2."<project number>".PLAMS_Amended_2022')
from
	NPD_i2."<project number>".PLAMS_Amended_2022
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
	from fft.wip#plams
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
	select laestab_anon from fft.wip#plams
	) _
where
	laestab_anon <> ''
	and laestab_anon collate Latin1_General_BIN not in (
		select laestab_anon
		from fft.laestab_anon
		)
group by
	laestab_anon
;

--------------------------------------------------------------------------------
-- main load start
--------------------------------------------------------------------------------

insert fft.plams
select
	year,
	start_date,
	end_date,
	fuzzy_end_date,
	qan,
	disc_code,
	sublevno,
	grade,
	traineeship,
	fft_person_id,
	institution_id,
	row_id = row_number() over (
		partition by
			fft_person_id,
			qan,
			year,
			institution_id
		order by (select 1)
		),
	source_id
from
	fft.wip#plams
	left join fft.person_lookup on pmr collate Latin1_General_BIN = pupil_matching_reference
	left join fft.laestab_anon s on s.laestab_anon = wip#plams.laestab_anon collate Latin1_General_BIN
;
