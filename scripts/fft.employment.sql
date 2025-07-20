
-- In order to use this script, you will need to change the name of the
-- references to source objects in the code below. LEO projects will generally
-- need to uses a reference of the form
--     LILR_i2."<project number>".learners
--     LEO_i2."<project number>".education_records_lookup
-- though that may change in future.
-- You can use find-replace to change the string
--     <project number>
-- to the appropriate value.

-- In our projects, we are usually interested in when an individual was employed
-- (at all) and not in whether they have multiple employments on any given day;
-- we therefore deduplicate the employment records, though we are aware this is
-- lossy and may not be ideal in some use cases.

if schema_id('fft') is null
	exec ('create schema fft;');

if object_id('fft.employment') is null
create table fft.employment (
	edukey char(14) not null,
	start_date date,
	end_date date,
	fuzzy_start_date bit,
	fuzzy_end_date bit,
	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,
	primary key(fft_person_id, start_date, end_date)
	);
else truncate table fft.employment;

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
	edukey char(14) collate Latin1_General_BIN not null
	);
else truncate table #lookup;

declare @ae_id bigint = 0

while 1 = 1
begin
	insert #lookup
	select top 1000000 with ties
		ae_id,
		edukey
	from
		LEO_i2."<project number>".learner_ae_id_to_edukey_lookup
	where
		ae_id > @ae_id
	group by
		ae_id,
		edukey
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
	1 multiplex,
	case multiplex when 1 then ae_id end,
	null pupil_matching_reference,
	null external_id,
	edukey
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
set leo_edukey = edukey
from
	fft.person_lookup pl
	inner join (
	select
		ae_id,
		edukey = min(edukey)
	from
		#lookup
	group by
		ae_id
	) lk
		on	pl.ae_id = lk.ae_id
where
	leo_edukey is null
	and multiplex = 1
;
insert fft.person_lookup
select
	fft_person_id,
	(select max(multiplex) from fft.person_lookup where fft_person_id = pl.fft_person_id) + r multiplex,
	null ae_id,
	null pupil_matching_reference,
	null external_id,
	edukey
from
	(
	select
		edukey,
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
				leo_edukey,
				ae_id = min(ae_id) over (partition by fft_person_id)
			from
				fft.person_lookup
			) _
		where
			leo_edukey = edukey
			and ae_id = lk.ae_id
		)
	group by
		edukey
	) pl
;
insert fft.person_lookup
select
	(select max(fft_person_id) from fft.person_lookup)
	+ row_number() over (order by (select 1)),
	1 multiplex,
	null ae_id,
	null pupil_matching_reference,
	null external_id,
	edukey
from
	(
	select distinct edukey = edukey collate Latin1_General_BIN
	from leo_i2."<project number>".leo_employment
	where
		edukey <> ''
		and edukey collate Latin1_General_BIN not in (
		select leo_edukey
		from fft.person_lookup
		where leo_edukey is not null
		)
	) _
;

--------------------------------------------------------------------------------
-- main load start
--------------------------------------------------------------------------------

insert fft.employment
select
	max(leo_edukey),
	startdate,
	enddate,
	fuzzy_start_date = min(uncertainstartdate+0),
	fuzzy_end_date = min(uncertainenddate+0),
	fft_person_id
from
	LEO_i2."<project number>".leo_employment e
	left join fft.person_lookup k
		on	e.edukey collate Latin1_General_BIN = k.leo_edukey
where
	fft_person_id is not null
group by
	fft_person_id,
	startdate,
	enddate
;
