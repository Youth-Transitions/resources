
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

if object_id('fft.nccis_spells') is null
create table fft.nccis_spells (
	pupil_matching_reference char(18) /* collate Latin1_General_BIN */ not null,
	spell_type_code tinyint not null,
	in_custody as cast(spell_type_code&128 as bit),
	in_education as cast(spell_type_code&1 as bit),
	in_employment as cast(spell_type_code&2 as bit),
	in_training as cast(spell_type_code&4 as bit),
	neet_active as cast(spell_type_code&8 as bit),
	neet_inactive as cast(spell_type_code&16 as bit),
	self_employed as cast(spell_type_code&32 as bit),
	start_date date not null,
	end_date date not null,
	original_start_date date,
	fft_person_id int not null,
	-- warning: datediff does not round; it looks only at the difference in the
	-- month, without accounting for the day within the month.
	-- for example, though these two are the same number of days different, the
	-- month difference is not the same:
	--  	1 + datediff(m, Jan 31st 2025, Mar 1st 2025) = 3
	--  	1 + datediff(m, Jan 1st 2025, Jan 31st 2025) = 1
	length_in_months as 1 + datediff(m, start_date, end_date),
	primary key (fft_person_id, start_date)
	);
else truncate table fft.nccis_spells;

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
	pmr,
	null external_id,
	null edukey
from
	(
	select distinct nccis_pupilmatchingrefanonymous pmr
	from npd_i2."<project number>".nccis_2011_to_2021
	where
		nccis_pupilmatchingrefanonymous <> ''
		and nccis_pupilmatchingrefanonymous collate Latin1_General_BIN not in (
		select pupil_matching_reference
		from fft.person_lookup
		where pupil_matching_reference is not null
		)
	) _
;

drop table #lookup;

--------------------------------------------------------------------------------
-- main load
--------------------------------------------------------------------------------

insert fft.nccis_spells
select
	nccis_pupilmatchingrefanonymous,
	max(case when activity in (110, 120, 210, 220, 230, 240, 250, 260, 270, 280, 290) then 1 else 0 end)
	| max(case when activity in (310, 320, 330, 340, 350, 360, 550, 551) then 2 else 0 end)
	| max(case when activity in (410, 420, 430, 440, 450, 460, 530) then 4 else 0 end)
	| max(case when activity in (510, 520, 540, 610, 615, 616, 619) then 8 else 0 end)
	| max(case when activity in (140, 620, 630, 640, 650, 660, 670, 680) then 16 else 0 end)
	| max(case when activity in (130, 290, 710) then 128 else 0 end)
	| max(case when activity in (380,381) then 32 else 0 end),
	start_date,
	max(dateadd(d,-1,dateadd(m,1,month_start_date))),
	nccis_current_activity_start_date,
	fft_person_id
from
	npd_i2."<project number>".nccis_2011_to_2021
	outer apply (
		select
			-- though NCCIS uses academic years, the monthno is the calendar month!
			month_start_date = cast(
				case when nccis_monthno < 9 then right(nccis_acadyr, 4) else left(nccis_acadyr, 4) end
				+ '-' + right('0'+cast(nccis_monthno as varchar(max)), 2)
				+ '-01' as date)
		) _msd
	outer apply (
		select
			start_date = isnull(
				nccis_current_activity_start_date,
				month_start_date
				),
			activity = nccis_current_activity_code
		) _
	left join fft.person_keys on nccis_pupilmatchingrefanonymous = pupil_matching_reference
where
	nccis_pupilmatchingrefanonymous <> ''
group by
	fft_person_id,
	start_date
;

--------------------------------------------------------------------------------
-- post-processing
--------------------------------------------------------------------------------

-- If someone is in custody, that overrides everything else...
update fft.nccis_spells
set spell_type_code = 128
where spell_type_code > 128
;

-- If someone is doing multiple things that start at the same time, that's a
-- data conflict, so remove it...
delete fft.nccis_spells
where spell_type_code not in (1,2,4,8,16,32,64,128)
;

-- If one record is contained inside another, it can be discarded...
delete a
from
	fft.nccis_spells a
	inner join fft.nccis_spells b
		on	a.fft_person_id = b.fft_person_id
			and b.spell_type_code in (b.spell_type_code, 128)
			and b.start_date < a.end_date
			and a.end_date <= b.end_date
;

-- Custody overlap override...
update a
set start_date = dateadd(d,1,b.end_date)
from
	fft.nccis_spells s
	cross apply (
	select top 1
		end_date
	from
		fft.nccis_spells
	where
		fft_person_id = a.fft_person_id
		and spell_type_code = 128
		and start_date < a.start_date
		and end_date >= a.start_date
	order by
		end_date desc
	) b
;

-- If spells overlap, shorten the end_date...
update a
set end_date = dateadd(d,-1,b.start_date)
from
	nccis_spells a
	cross apply (
	select top 1
		start_date
	from
		nccis_spells
	where
		fft_person_id = a.fft_person_id
		and start_date > a.start_date
		and start_date <= a.end_date
	order by
		start_date
	) b
;

-- Assign some date between spells to set as the transition date and reset start
-- and end to match...
update nccis_spells
set start_date = dateadd(m, -cast((datediff(m, prev_date, start_date)) * r as int), start_date)
from
	(
	select
		start_date,
		-- the RAND function assigns the same value to all records; this
		-- provides a different pseudo-random floating point number in [0, 1)
		-- for each row
		r = ((checksum(newid()) & 0x7FFFF000) / cast(0x7FFFFFFF+0 as real)),
		prev_date = max(end_date) over (
			partition by fft_person_id
			order by start_date
			rows between 1 preceding and 1 preceding
			)
	from
		fft.nccis_spells
	) nccis_spells
where
	datediff(m, prev_date, start_date) > 1
;
update nccis_spells
set end_date = dateadd(d, -1, next_date)
from
	(
	select
		end_date,
		next_date = min(start_date) over (
			partition by fft_person_id
			order by start_date
			rows between 1 following and 1 following
			)
	from
		fft.nccis_spells
	) nccis_spells
where
	datediff(d, end_date, next_date) > 1
;

-- Collapse records into single spells...
while 1 = 1
begin
	update a
	set end_date = b.end_date
	from
		fft.nccis_spells a
		inner join fft.nccis_spells b
		on	b.fft_person_id = a.fft_person_id
			and b.spell_type_code = a.spell_type_code
			and datediff(d, a.end_date, b.start_date) = 1
	where
		a.end_date = b.end_date
	;
	if @@rowcount = 0
		break;
end

-- Remove duplicate records...
delete fft.nccis_spells
where exists (
	select *
	from fft.nccis_spells x
	where fft_person_id = nccis_spells.fft_person_id
		and spell_type_code = nccis_spells.spell_type_code
		and end_date = nccis_spells.end_date
		and start_date < nccis_spells.start_date
	)
;
