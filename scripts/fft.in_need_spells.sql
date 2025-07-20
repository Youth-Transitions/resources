
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

--drop table fft.in_need_spells;
if object_id('fft.in_need_spells') is null
begin
create table fft.in_need_spells (
	-- The fft_person_id is a numeric identifier for the individual, assigned by
	-- FFT and used across all datasets and example scripts.
	fft_person_id int not null,

	start_date date not null,
	end_date date not null,

	la_code smallint,
	);	
create unique clustered index cq_cin_spells on fft.in_need_spells (fft_person_id, start_date, la_code);
alter table fft.in_need_spells rebuild partition = all with (data_compression = page);
end
else truncate table fft.in_need_spells;

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
	select distinct pmr = cin_pupilmatchingrefanonymous collate Latin1_General_BIN
	from npd_i2."<project number>".cin_2009_to_2021
	where
		cin_pupilmatchingrefanonymous <> ''
		and cla_pupilmatchingrefanonymous collate Latin1_General_BIN not in (
		select pupil_matching_reference
		from fft.person_lookup
		where pupil_matching_reference is not null
		)
	) _
;

drop table #lookup;

--------------------------------------------------------------------------------

insert fft.in_need_spells
select
	fft_person_id,
	cin_referraldate,
	max(cin_cinclosuredate),
	cin_la_geog
from
	npd_i2."<project number>".cin_2009_to_2021
	left join fft.person_lookup
		on pupil_matching_reference = cin_pupilmatchingrefanonymous collate Latin1_General_BIN
where
	cin_referraldate <= cin_cinclosuredate
	and isnull(cin_referralnfa, 0) = 0
	and isnull(cin_reasonforclosure, '') <> 'RC8'
group by
	fft_person_id,
	cin_referraldate,
	cin_la_geog
;

while @@rowcount > 0
	update s
	set end_date = o.end_date
	from
		fft.in_need_spells s
		cross apply (
		select top 1 end_date
		from fft.in_need_spells
		where
			fft_person_id = s.fft_person_id
			and isnull(la_code, 0) = isnull(s.la_code, 0)
			and start_date <= s.end_date
			and end_date > s.end_date
		order by
			end_date desc
		) o
	;

delete fft.in_need_spells
where exists (
	select *
	from fft.in_need_spells x
	where
		fft_person_id = in_need_spells.fft_person_id
		and isnull(la_code, 0) = isnull(in_need_spells.la_code, 0)
		and end_date = in_need_spells.end_date
		and start_date < in_need_spells.start_date
	)
;
