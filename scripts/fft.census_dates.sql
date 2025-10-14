
if object_id('fft.census_dates') is null
create table fft.census_dates (
	fft_person_id int not null,
	year smallint not null,
	term_id tinyint not null,
	institution_id int not null,
	min_entry_date date not null,
	max_entry_date date not null,
	min_leaving_date date not null,
	max_leaving_date date not null,
	entry_date date,
	leaving_date date,
	primary key (fft_person_id, year, term_id, institution_id)
	);
else truncate table fft.census_dates;

insert fft.census_dates
select
	fft_person_id,
	year,
	term_id,
	institution_id,
	isnull(min(entry_date), '1900-01-01'),
	coalesce(
		max(entry_date),
		case when max(leaving_date) < max(max_entry_date) then max(leaving_date) end,
		max(max_entry_date)
		),
	coalesce(
		min(nullif(leaving_date, '9999-12-31')),
		case when min(entry_date) > min(min_leaving_date) then min(entry_date) end,
		min(min_leaving_date),
		'9999-12-31'
		),
	coalesce(
		max(nullif(leaving_date, '9999-12-31')),
		max(max_leaving_date),
		'9999-12-31'
		),
	case min(entry_date) when max(entry_date) then min(entry_date) end,
	case min(leaving_date) when max(leaving_date) then min(leaving_date) end
from
	fft.census_details with(nolock)
	outer apply (
	select
		max_entry_date = cast(
			case term_id
				when 1 then cast(year-1 as varchar(max))+'-10-31'
				when 3 then cast(year as varchar(max))+'-05-31'
				else cast(year as varchar(max))+'-01-31'
			end as date),
		min_leaving_date = cast(
			case
				when term_id = 1 and onroll = 0 then cast(year-1 as varchar(max))+'-05-12'
				when term_id = 1 or term_id = 2 and onroll = 0 then cast(year-1 as varchar(max))+'-10-12'
				when term_id in (0, 2) or term_id = 3 and onroll = 0 then cast(year as varchar(max))+'-01-12'
				else cast(year as varchar(max))+'-05-12'
			end as date),
		max_leaving_date = cast(
			case
				when term_id = 0 then cast(year+1 as varchar(max))+'-05-12'
				when term_id = 1 and onroll = 0 then cast(year-1 as varchar(max))+'-10-12'
				when term_id = 1 or term_id = 2 and onroll = 0 then cast(year as varchar(max))+'-01-12'
				when term_id = 2 or term_id = 3 and onroll = 0 then cast(year as varchar(max))+'-05-12'
				else cast(year as varchar(max))+'-10-12'
			end as date)
		) med
group by
	fft_person_id,
	year, term_id,
	institution_id
having
	count(1) > count(entry_date)
	or count(1) > count(leaving_date)
;

update cd
set leaving_date = isnull(
		case min_leaving_ed when max_leaving_ed then min_leaving_ed end,
		case when min_entry = max_entry and min_leaving = max_leaving then min_leaving end
		)
from
	(
	select
		leaving_date,
		min_leaving_ed = min(min_leaving_date) over (partition by fft_person_id, institution_id, min_entry_date),
		max_leaving_ed = max(nullif(max_leaving_date, '9999-12-31')) over (partition by fft_person_id, institution_id, min_entry_date),
		min_entry = min(nullif(min_entry_date, '1900-01-01')) over (partition by fft_person_id, institution_id),
		max_entry = max(max_entry_date) over (partition by fft_person_id, institution_id),
		min_leaving = min(min_leaving_date) over (partition by fft_person_id, institution_id),
		max_leaving = max(nullif(max_leaving_date, '9999-12-31')) over (partition by fft_person_id, institution_id)
	from
		fft.census_dates
	) cd
where
	leaving_date is null
;

update cd
set max_entry_date = start_date
from
	fft.census_dates cd
	inner join fft.exclusions e
		on	cd.fft_person_id = e.fft_person_id
			and cd.institution_id = e.institution_id
where
	case min_entry_date when '1900-01-01' then dateadd(y, -1, max_entry_date) else min_entry_date end <= start_date
	and max_entry_date > start_date
;
update cd
set min_leaving_date = start_date,
	leaving_date = isnull(leaving_date, case is_permanent when 1 then start_date end)
from
	fft.census_dates cd
	inner join fft.exclusions e
		on	cd.fft_person_id = e.fft_person_id
			and cd.institution_id = e.institution_id
where
	min_leaving_date < start_date
	and case max_leaving_date when '9999-12-31' then dateadd(y, 1, min_leaving_date) else max_leaving_date end >= start_date
;

update fft.census_dates
set entry_date = min_entry_date
where
	entry_date is null
	and nullif(min_entry_date, '1900-01-01') = max_entry_date
;
update fft.census_dates
set leaving_date = min_leaving_date
where
	leaving_date is null
	and min_leaving_date = nullif(max_leaving_date, '9999-12-31')
;

update fft.census_dates
set entry_date = cast(year(max_entry_date) as varchar(max))+'-01-01'
where
	entry_date is null
	and month(dateadd(m, 4, nullif(min_entry_date, '1900-01-01'))) between 2 and 5
	and max_entry_date between cast(year(dateadd(m, 4, min_entry_date)) as varchar(max))+'-01-01' and cast(year(dateadd(m, 4, min_entry_date)) as varchar(max))+'-04-30'
;
update fft.census_dates
set entry_date = cast(year(max_entry_date) as varchar(max))+'-04-01'
where
	entry_date is null
	and month(dateadd(d, 21, min_entry_date)) between 2 and 5
	and max_entry_date between cast(year(min_entry_date) as varchar(max))+'-04-01' and cast(year(dateadd(m, 4, min_entry_date)) as varchar(max))+'-05-31'
;
update fft.census_dates
set entry_date = cast(year(dateadd(m, -8, max_entry_date)) as varchar(max))+'-09-01'
where
	entry_date is null
	and min_entry_date <= cast(year(dateadd(m, -8, max_entry_date)) as varchar(max))+'-09-01'
;

update fft.census_dates
set min_leaving_date = entry_date
where
	leaving_date is null
	and min_leaving_date < entry_date
;

update fft.census_dates
set leaving_date = cast(year(max_leaving_date) as varchar(max))+'-01-01'
where
	leaving_date is null
	and month(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) between 2 and 5
	and nullif(max_leaving_date, '9999-12-31') between cast(year(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) as varchar(max))+'-01-01' and cast(year(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) as varchar(max))+'-04-30'
;
update fft.census_dates
set leaving_date = cast(year(max_leaving_date) as varchar(max))+'-04-01'
where
	leaving_date is null
	and month(dateadd(d, 21, nullif(min_leaving_date, '9999-12-31'))) between 1 and 5
	and max_leaving_date between cast(year(min_leaving_date) as varchar(max))+'-04-01' and cast(year(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) as varchar(max))+'-05-31'
;
update fft.census_dates
set leaving_date = cast(year(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) as varchar(max))+'-09-01'
where
	leaving_date is null
	and max_leaving_date >= cast(year(dateadd(m, 4, nullif(min_leaving_date, '9999-12-31'))) as varchar(max))+'-09-01'
;

update fft.census_dates
set entry_date = dateadd(d, datediff(d, min_entry_date, max_entry_date) / 2, min_entry_date)
where entry_date is null
;

update fft.census_dates
set leaving_date = dateadd(d, datediff(d, min_leaving_date, max_leaving_date) / 2, min_leaving_date)
where leaving_date is null
;

