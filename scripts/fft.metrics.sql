
-- Minimum year for metrics
declare @min_year smallint = 2006;

-- Maximum year for metrics
declare @max_year smallint = 2022;

-- Number of "Post-16" months for monthly metrics (starting at the beginning of
-- the year they are academic age 16)
declare @post16_month_count tinyint = 24;

--------------------------------------------------------------------------------

if object_id('fft.spell_type') is null
begin
	create table fft.spell_type (
		type_id tinyint not null,
		type_code char(4) collate Latin1_General_BIN not null,
		description varchar(max) not null
		);
	insert fft.spell_type
	select 1, '.oow', 'Out of work benefits'
	union select 2, '.iw', 'In work benefits'
	
	union select 11, 'AA', 'AA'
	union select 12, 'BB', 'BB'
	union select 13, 'DLA', 'DLA'
	union select 14, 'ESA', 'ESA'
	union select 15, 'IB', 'IB'
	union select 16, 'ICA', 'ICA'
	union select 17, 'IS', 'IS'
	union select 18, 'JSA', 'JSA'
	union select 19, 'JTA', 'JTA'
	union select 20, 'PC', 'PC'
	union select 21, 'PIB', 'PIB'
	union select 22, 'RP', 'RP'
	union select 23, 'SDA', 'SDA'
	union select 24, 'UAA', 'UAA'
	union select 25, 'UAB', 'UAB'
	union select 26, 'UBC', 'UBC'
	union select 27, 'UBD', 'UBD'
	union select 28, 'UCE', 'UCE'
	union select 29, 'UDF', 'UDF'
	union select 30, 'UNA', 'UNA'
	union select 31, 'WB', 'WB'
	
	union select 48, 'PIP', 'Personal Independence Payment'
	
	union select 101, '.sch', 'School'
	union select 102, '.fe', 'Further Education'
	union select 103, '.he', 'Higher Education'
	union select 104, '.emp', 'Employment'
	;
end

if object_id('fft.spells') is null
create table fft.spells (
	fft_person_id int not null,
	type_id tinyint not null,
	start_date date not null,
	end_date date not null,
	primary key (fft_person_id, start_date, type_id)
	);
else truncate table fft.spells;

if object_id('fft.metrics') is null
create table fft.metrics (
	fft_person_id int not null,
	year smallint not null,
	type_id tinyint not null,
	count_of_days smallint not null,
	max_length smallint not null,
	is_academic_year bit not null,
	is_tax_year bit not null,
	primary key (fft_person_id, year, type_id, is_academic_year, is_tax_year)
	);
else truncate table fft.metrics;

-- Notes:
-- + a suffix acyear indicates a metric that relates to data that usually uses
--   tax year, but calculated for an academic year
-- + a suffix taxyear indicates a metrics that relates to data that usually uses
--   academic year, but calculates for a tax year
-- + "continuous" means a continuous spell of 181 days or more (the shortest
--   possible 6 month period), but not all of the spell has to be in the given
--   year
-- + earnings columns are as in source, except for those with a 2015 suffix,
--   which account for inflation, using on 2015 prices

if object_id('fft.metrics_wide') is null
create table fft.metrics_wide (
	fft_person_id int not null,
	year smallint not null,

	earnings int,
	earnings_2015 real,
	self_employed_earnings int,
	self_employed_earnings_2015 real,

	days_in_employment smallint not null,
	in_continuous_employment bit not null,
	has_employment as cast(days_in_employment as bit),
	days_in_employment_acyear smallint not null,
	in_continuous_employment_acyear bit not null,
	has_employment_acyear as cast(days_in_employment_acyear as bit),
	earnings_per_day as cast(earnings as real) / nullif(days_in_employment, 0),
	earnings_per_day_2015 as earnings_2015 / nullif(days_in_employment, 0),

	days_on_in_work_benefits smallint not null,
	continuous_in_work_benefits bit not null,
	has_in_work_benefits as cast(days_on_in_work_benefits as bit),
	days_on_in_work_benefits_acyear smallint not null,
	continuous_in_work_benefits_acyear bit not null,
	has_in_work_benefits_acyear as cast(days_on_in_work_benefits_acyear as bit),
	days_on_out_of_work_benefits smallint not null,
	continuous_out_of_work_benefits bit not null,
	has_out_of_work_benefits as cast(days_on_out_of_work_benefits as bit),
	days_on_out_of_work_benefits_acyear smallint not null,
	continuous_out_of_work_benefits_acyear bit not null,
	has_out_of_work_benefits_acyear as cast(days_on_out_of_work_benefits_acyear as bit),

	days_in_school smallint not null,
	days_in_school_taxyear smallint not null,
	days_in_further_education smallint not null,
	days_in_further_education_taxyear smallint not null,
	days_in_higher_education smallint not null,
	days_in_higher_education_taxyear smallint not null,

	primary key (fft_person_id, year)
	);
else truncate table fft.metrics_wide;

if object_id('fft.metrics_monthly') is null
create table fft.metrics_monthly (
	fft_person_id int not null,
	start_date date not null,
	end_date as dateadd(d, -1, dateadd(m, 1, start_date)),
	days_in_school tinyint,
	days_in_further_education tinyint,
	days_in_higher_education tinyint,
	days_in_employment tinyint,
	days_on_in_work_benefits tinyint,
	days_on_out_of_work_benefits tinyint,
	days_in_custody tinyint,
	days_in_education_nccis tinyint,
	days_in_training_nncis tinyint,
	days_in_employment_nccis tinyint,
	days_self_employed_nccis tinyint,
	days_active_neet_nccis tinyint,
	days_inactive_neet_nccis tinyint,

	primary key (fft_person_id, start_date)
	);
else truncate table fft.metrics_monthly;

--------------------------------------------------------------------------------
-- spells
--------------------------------------------------------------------------------

if object_id('fft.benefits') is not null
	insert fft.spells
	select
		fft_person_id,
		type_id.type_id,
		start_date,
		max(end_date)
	from
		fft.benefits
		inner join fft.spell_type
			on	type_code = benefit_type collate Latin1_General_BIN
		cross apply (
		select type_id
		from fft.spell_type
		where type_code = benefit_type collate Latin1_General_BIN
		union all select type_id
		from fft.spell_type
		where type_code = case out_of_work_benefit when 0 then '.iw' when 1 then '.oow' end
		) type_id
	where
		start_date < end_date
	group by
		fft_person_id,
		type_id.type_id,
		start_date
	;

if object_id('fft.census_details') is not null
	insert fft.spells
	select
		fft_person_id,
		(select type_id from fft.spell_type where description = 'School'),
		entry_date,
		max(end_date)
	from
		fft.census_details
		outer apply (
		select end_date = isnull(
			leaving_date,
			case nullif(term_id, 0) + 1 - isnull(onroll, 1)
				when 0 then cast(year-1 as varchar(max))+'-08-31'
				when 1 then cast(year-1 as varchar(max))+'-12-31'
				when 2 then cast(year as varchar(max))+'-04-01'
				else cast(year as varchar(max))+'-08-31'
			end
			)
		) end_date
	where
		entry_date < end_date
	group by
		fft_person_id,
		entry_date
	;

if object_id('fft.ilr_aims') is not null
	insert fft.spells
	select
		fft_person_id,
		(select type_id from fft.spell_type where description = 'Further Education'),
		start_date,
		max(end_date.end_date)
	from
		fft.ilr_aims
		outer apply (
		select end_date = isnull(
			nullif(end_date, '1900-01-01'),
			case
				when completion_status = 3 then null
				else isnull(expected_end_date, cast(year as varchar(max))+'-08-31')
			end
			)
		) end_date
	where
		start_date < end_date.end_date
	group by
		fft_person_id,
		start_date
	;

if object_id('fft.hesa') is not null
	insert fft.spells
	select
		fft_person_id,
		(select type_id from fft.spell_type where description = 'Higher Education'),
		start_date,
		max(end_date)
	from
		fft.hesa
	where
		start_date < end_date
	group by
		fft_person_id,
		start_date
	;

if object_id('fft.employment') is not null
	insert fft.spells
	select
		fft_person_id,
		(select type_id from fft.spell_type where description = 'Employment'),
		start_date,
		max(end_date)
	from
		fft.employment
	where
		start_date < end_date
	group by
		fft_person_id,
		start_date
	;

while 1 = 1
begin
	delete a
	from
		fft.spells a
		inner join fft.spells b
			on	a.fft_person_id = b.fft_person_id
				and a.type_id = b.type_id
				and a.start_date > b.start_date
				and a.end_date <= b.end_date
	;
	update a
	set end_date = o.end_date
	from
		fft.spells a
		cross apply (
			select top 1 end_date
			from fft.spells
			where
				fft_person_id = a.fft_person_id
				and type_id = a.type_id
				and start_date <= a.end_date
				and end_date > a.end_date
			order by
				end_date
			) o
	;
	if @@rowcount = 0
		break;
end;

declare @year varchar(max) = @min_year;

-- fft.metrics_wide and fft.metrics_monthly use fft.earnings and fft.prices_2015
-- and fft.nccis_spells, but if they don't exist, we use empty 'dummy' objects
-- (proxies) so the script will run anyway.
-- These are cleaned up at the end of the script.

if object_id('fft.earnings') is null
	exec ('
	create view fft.earnings as
	select 0 fft_person_id, 0 year, 0 self_employed, 0 value
	where 0 = 1
	;');
if object_id('fft.prices_2015') is null
	exec ('
	create view fft.prices_2015 as
	select 0 year, 0 value
	where 0 = 1
	;');
if object_id('fft.nccis_spells') is null
	exec ('
	create view fft.nccis_spells (
	select
		0 fft_person_id, getdate() start_date, getdate() end_date,
		0 in_custody, 0 in_education, 0 in_employment, 0 in_training,
		0 neet_active, 0 neet_inactive, 0 self_employed
	where 0 = 1
	;');

while @year < @max_year + 1
begin
	declare
		@start_date date = cast(cast(@year - 1 as varchar(max)) + '-09-01' as date),
		@end_date date = cast(@year + '-08-31' as date);
	
	insert fft.metrics
	select
		fft_person_id,
		@year,
		type_id,
		sum(1 + datediff(d, x.start_date, x.end_date)),
		case when max(1 + datediff(d, s.start_date, s.end_date)) > 0x7FFF then 0x7FFF
			else max(1 + datediff(d, s.start_date, s.end_date)) end,
		1 is_academic_year,
		0 is_tax_year
	from
		fft.spells s
		outer apply (
			select
				start_date = case when s.start_date < @start_date then @start_date else s.start_date end,
				end_date = case
					when s.end_date > @end_date then @end_date
					when s.end_date > getdate() then cast(getdate() as date)
					else s.end_date
					end
			) x
	where
		s.start_date <= @end_date
		and s.end_date >= @start_date
		and s.start_date <= s.end_date
	group by
		fft_person_id,
		type_id
	;

	set @start_date = cast(cast(@year - 1 as varchar(max)) + '-04-01' as date);
	set @end_date = cast(@year + '-03-31' as date);

	insert fft.metrics
	select
		fft_person_id,
		@year,
		type_id,
		sum(1 + datediff(d, x.start_date, x.end_date)),
		case when max(1 + datediff(d, s.start_date, s.end_date)) > 0x7FFF then 0x7FFF
			else max(1 + datediff(d, s.start_date, s.end_date)) end,
		0 is_academic_year,
		1 is_tax_year
	from
		fft.spells s
		outer apply (
			select
				start_date = case when s.start_date < @start_date then @start_date else s.start_date end,
				end_date = case
					when s.end_date > @end_date then @end_date
					when s.end_date > getdate() then cast(getdate() as date)
					else s.end_date
					end
			) x
	where
		s.start_date <= @end_date
		and s.end_date >= @start_date
		and s.start_date <= s.end_date
	group by
		fft_person_id,
		type_id
	;

	insert fft.metrics_wide
	select
		p.fft_person_id,
		p.year,

		e.value earnings,
		e.value * 100/q.value e2015,
		e.se_value self_employed_earnings,
		e.se_value * 100/q.value see2015,

		isnull(ED, 0) days_in_employment,
		sign(isnull(EC, 0) / 181) in_continuous_employment,
		isnull(EDA, 0) days_in_employment_acyear,
		sign(isnull(ECA, 0) / 181) in_continuous_employment_acyear,

		isnull(ID, 0) days_on_in_work_benefits,
		sign(isnull(IC, 0) / 181) continuous_in_work_benefits,
		isnull(IDA, 0) days_on_in_work_benefits_acyear,
		sign(isnull(ICA, 0) / 181) continuous_in_work_benefits_acyear,
		isnull(OD, 0) days_on_out_of_work_benefits,
		sign(isnull(OC, 0) / 181) continuous_out_of_work_benefits,
		isnull(ODA, 0) days_on_out_of_work_benefits_acyear,
		sign(isnull(OCA, 0) / 181) continuous_out_of_work_benefits_acyear,

		isnull(SD, 0) days_in_school,
		isnull(SDT, 0) days_in_school_taxyear,
		isnull(FD, 0) days_in_further_education,
		isnull(FDT, 0) days_in_further_education_taxyear,
		isnull(HD, 0) days_in_higher_education,
		isnull(HDT, 0) days_in_higher_education_taxyear
	from
		(
		select
			fft_person_id,
			year,
			ED = sum(case when is_tax_year = 1 and type_id = 104 then count_of_days end),
			EC = max(case when is_tax_year = 1 and type_id = 104 then max_length end),
			EDA = sum(case when is_academic_year = 1 and type_id = 104 then count_of_days end),
			ECA = max(case when is_academic_year = 1 and type_id = 104 then max_length end),
			ID = sum(case when is_tax_year = 1 and type_id = 2 then count_of_days end),
			IC = max(case when is_tax_year = 1 and type_id = 2 then max_length end),
			IDA = sum(case when is_academic_year = 1 and type_id = 2 then count_of_days end),
			ICA = max(case when is_academic_year = 1 and type_id = 2 then max_length end),
			OD = sum(case when is_tax_year = 1 and type_id = 1 then count_of_days end),
			OC = max(case when is_tax_year = 1 and type_id = 1 then max_length end),
			ODA = sum(case when is_academic_year = 1 and type_id = 1 then count_of_days end),
			OCA = max(case when is_academic_year = 1 and type_id = 1 then max_length end),
			SD = sum(case when is_academic_year = 1 and type_id = 101 then count_of_days end),
			SDT = sum(case when is_tax_year = 1 and type_id = 101 then count_of_days end),
			FD = sum(case when is_academic_year = 1 and type_id = 102 then count_of_days end),
			FDT = sum(case when is_tax_year = 1 and type_id = 102 then count_of_days end),
			HD = sum(case when is_academic_year = 1 and type_id = 103 then count_of_days end),
			HDT = sum(case when is_tax_year = 1 and type_id = 103 then count_of_days end)
		from
			fft.metrics
		where
			year = @year
			and type_id in (1,2,101,102,103,104)
		group by
			fft_person_id,
			year
		) p
		outer apply (
		select
			sum(case self_employed when 0 then value else 0 end) value,
			sum(case self_employed when 1 then value else 0 end) se_value
		from fft.earnings t
		where
			t.fft_person_id = p.fft_person_id
			and t.year = p.year
		) e
		left join fft.prices_2015 q
			on	q.year = p.year
	;

	set @year = @year + 1;
end

declare @id int = 0;
declare @max_id int = (select max(fft_person_id) from fft.person_lookup);
declare @batch_size int = 5500000;

-- looping on person id is more efficient (less data fragmentation), but less
-- straight-forward; we used year above so the loop was more easily understood,
-- but year is less useful here
while @id < @max_id
begin
	;with n as (
		-- this is a recursive CTE; it produces integers in the range [1,@post_month_count]
		select 1 n
		union all select n + 1 from n where n < @post16_month_count
		)
	insert fft.metrics_monthly
	select
		fft_person_id,
		start_date,
		isnull(spells.SD, 0),
		isnull(spells.FD, 0),
		isnull(spells.HD, 0),
		isnull(spells.ED, 0),
		isnull(spells.ID, 0),
		isnull(spells.OD, 0),
		isnull(nccis.CD, 0),
		isnull(nccis.SD, 0),
		isnull(nccis.FD, 0),
		isnull(nccis.ED, 0),
		isnull(nccis.ED1, 0),
		isnull(nccis.AD, 0),
		isnull(nccis.ID, 0)
	from
		(
		select
			*,
			-- SQL has no modal average; this is one way to calculate it
			"priority" = row_number() over (
				partition by fft_person_id
				order by max_count desc, min_date desc
				)
		from
			(
			select
				fft_person_id,
				min_date = cast(cast(year - academic_age + 15 as varchar(max))+'-09-01' as date),
				count = count(1),
				max_count = max(count(1)) over (partition by fft_person_id)
			from
				fft.census_details
			where
				fft_person_id >= @id
				and fft_person_id < @id + @batch_size
			group by
				fft_person_id,
				year - academic_age
			) _
		) sc
		outer apply (
		select
			start_date = dateadd(m, n - 1, min_date),
			end_date = dateadd(d, -1, dateadd(m, n, min_date))
		) dates
		outer apply (
		select
			SD = sum(case type_id when 101 then 1 + datediff(d, min_date, max_date) end),
			FD = sum(case type_id when 102 then 1 + datediff(d, min_date, max_date) end),
			HD = sum(case type_id when 103 then 1 + datediff(d, min_date, max_date) end),
			ED = sum(case type_id when 104 then 1 + datediff(d, min_date, max_date) end),
			ID = sum(case type_id when 2 then 1 + datediff(d, min_date, max_date) end),
			OD = sum(case type_id when 1 then 1 + datediff(d, min_date, max_date) end)
		from
			fft.spells
			outer apply (
			select
				min_date = case when start_date < dates.start_date then dates.start_date else start_date end,
				max_date = case when end_date > dates.end_date then dates.end_date else end_date end
			) _
		where
			fft_person_id = sc.fft_person_id
			and start_date >= dates.end_date
			and end_date <= dates.start_date
		) spells
		outer apply (
		select
			CD = sum(case in_custody when 1 then 1 + datediff(d, min_date, max_date) end),
			SD = sum(case in_education when 1 then 1 + datediff(d, min_date, max_date) end),
			FD = sum(case in_training when 1 then 1 + datediff(d, min_date, max_date) end),
			ED = sum(case in_employment when 1 then 1 + datediff(d, min_date, max_date) end),
			ED1 = sum(case self_employed when 1 then 1 + datediff(d, min_date, max_date) end),
			AD = sum(case neet_active when 1 then 1 + datediff(d, min_date, max_date) end),
			ID = sum(case neet_inactive when 1 then 1 + datediff(d, min_date, max_date) end)
		from
			fft.nccis_spells
			outer apply (
			select
				min_date = case when start_date < dates.start_date then dates.start_date else start_date end,
				max_date = case when end_date > dates.end_date then dates.end_date else end_date end
			) _
		) nccis
	where
		"priority" = 1
		and year(start_date) between @min_year and @max_year
	;
	set @id += @batch_size;
end

-- If these are views with no data they are probably proxies created earlier in
-- this script and should be removed. If they weren't, they are still empty so
-- there's no data lost.

if object_id('fft.earnings', 'v') is not null
	and not exists (select * from fft.earnings)
	drop view fft.earnings;

if object_id('fft.prices_2015', 'v') is not null
	and not exists (select * from fft.prices_2015)
	drop view fft.prices_2015;

if object_id('fft.nccis_spells', 'v') is not null
	and not exists (select * from fft.nccis_spells)
	drop view fft.nccis_spells;
