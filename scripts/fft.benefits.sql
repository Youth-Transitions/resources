
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

if object_id('fft.benefits') is null
create table fft.benefits (
	edukey char(14) not null,
	benefit_type char(3) not null,
	start_date date,
	end_date date,
	
	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,
	
	-- The row_id column is a simple indexer of records that would otherwise
	-- have the same set of values in the primary key columns; it is used to
	-- disambiguate them.
	row_id tinyint not null,
	
	out_of_work_benefit as case
		when benefit_type in (
			'AA','ESA','IB','ICA','IS','JSA','JTA','PC',
			'PIB','RP','SDA','UAA','UBC','UCE','UDF'
			) then 1
		when benefit_type in ('BB','DLA','PIP','UAB','UBD','UNA','WB') then 0
	end,
	
	primary key (fft_person_id, benefit_type, start_date, row_id)
	)
else truncate table fft.benefits;

if object_id('LEO_i2."<project number>".leo_benefit') is null
	return;

--------------------------------------------------------------------------------
-- compile source
--------------------------------------------------------------------------------
-- Though there is only one source, we have had problems loading directly from
-- the view provided in some projects...

if object_id('fft.wip#beneits') is null
begin
create table fft.wip#benefits (
	edukey char(14) collate Latin1_General_BIN not null,
	startdate date,
	enddate date,
	benefit_type char(3) not null
	);
create index ix_edukey on fft.wip#benefits(edukey);
end
else truncate table fft.wip#benefits;

insert fft.wip#benefits
select
	edukey,
	startdate,
	enddate,
	benefit_type
from
	LEO_i2."<project number>".leo_benefit
where
	edukey is not null
	and benefit_type is not null
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
	select distinct edukey
	from fft.wip#benefits
	where
		edukey <> ''
		and edukey not in (
		select leo_edukey
		from fft.person_lookup
		where leo_edukey is not null
		)
	) _
;

drop table #lookup;

--------------------------------------------------------------------------------
-- main load start
--------------------------------------------------------------------------------

insert fft.benefits
select
	edukey,
	benefit_type,
	startdate,
	enddate,
	fft_person_id,
	row_id = row_number() over (
		partition by fft_person_id, benefit_type, startdate
		order by (select 1)
		)
from
	fft.wip#benefits
	left join fft.person_lookup on leo_edukey = edukey
;

drop table fft.wip#benefits;
