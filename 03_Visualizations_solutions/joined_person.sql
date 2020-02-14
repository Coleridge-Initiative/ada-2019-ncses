
-- Join SED to everything

-- All drf_ids with an associated refid in the sdr_drfid xwalks have an associated record in the sdr, 
--   so we only need to match to the xwalk to generate our flag
-- Number of people dropped to XXX with new xwalk... 
--   Most likely due to year limits

-- Questions: 
--   Use dissertation field or doctoral field for field of study? 
--     Going with doctoral field for now
--   Use edited or raw primary source of support?


-- Join SED to everything

-- All drf_ids with an associated refid in the sdr_drfid xwalks have an associated record in the sdr, 
--   so we only need to match to the xwalk to generate our flag
-- Number of people dropped to ~3,500 with new xwalk... 
--   Most likely due to year limits

-- Questions: 
--   Use dissertation field or doctoral field for field of study? 
--     Going with doctoral field for now
--   Use edited or raw primary source of support?


with semester as (
  select 
	emp_number,
	max(modal_funder) as modal_funder,
	max(imputed_gender) as imputed_gender
  from ncses_2019.iris_semester
  group by emp_number
),	

all_drf_ids as (
  select distinct refid, drf_id from ncses_2019.sdr_drfid_2015
  union
  select distinct refid, drf_id from ncses_2019.sdr_drfid_2017 
),

umetrics as (
  select 
    xwalk.drf_id,
    case when refid is not null then 1 else 0 end as sdr_match,
    case when sem.emp_number is not null then 1 else 0 end as umetrics_semester_match,
    case when sem.modal_funder is not null then 1 else 0 end as umetrics_federal_funding,
    imputed_gender 
  from ncses_2019.sed_umetrics_xwalk xwalk
  left join all_drf_ids ids on xwalk.drf_id = ids.drf_id
  left join semester sem on xwalk.emp_number = sem.emp_number
),

joined_data as (
	select 
	  sed.drf_id, 
	  umetrics.umetrics_semester_match, 
	  umetrics.sdr_match, 
	  cast(sed.phdfield as int) as phdfield, 
	  umetrics.umetrics_federal_funding, 
	  sed.srceprim, 
	  case when (salaryv in (999996, 999998) or salaryv is null) then null else (salaryv :: float ::bigint)/1000 end as salary_k,
	  case when agedoc is null then null else agedoc :: float :: int end as age_at_diss,
	  udebtlvl,
	  gdebtlvl,
	  sed.phdcy :: int as phd_year,
	  sed.sex, 
	  umetrics.imputed_gender
	from ncses_2019.nsf_sed sed
	left join umetrics on sed.drf_id = umetrics.drf_id
)

select
  drf_id,
    case when sdr_match is null then 0 else sdr_match end sdr_match,
    case when umetrics_semester_match is null then 0 else umetrics_semester_match end umetrics_semester_match,
  case 
	when phdfield between 0 and 99 then 'Agriculture'
	when phdfield between 100 and 199 then 'Biological/Biomedical Sciences'
	when phdfield between 200 and 299 then 'Health Sciences'
	when phdfield between 300 and 399 then 'Engineering'
	when phdfield between 400 and 419 then 'Computer and Information Sciences'
	when phdfield between 420 and 499 then 'Mathematics'
	when phdfield between 500 and 599 then 'Physical Sciences'
	when phdfield between 600 and 649 then 'Psychology'
	when phdfield between 650 and 699 then 'Social Sciences'
	when phdfield between 700 and 799 then 'Humanities'
	when phdfield between 800 and 899 then 'Education'
	when phdfield between 900 and 939 then 'Business Management/Administration'
	when phdfield between 940 and 959 then 'Communication'
	--when phdfield between 960 and 989 then 'Fields Not Elsewhere Classified'
	else null 
  end as phd_major_field,
  umetrics_federal_funding, 
  srceprim, 
  sex, 
  salary_k,
  age_at_diss,
  phd_year,
case
	when udebtlvl in ('0', '1') then 0
	when udebtlvl = '11' then 1
	when udebtlvl = '12' then 2
	when udebtlvl = '13' then 3
	when udebtlvl = '14' then 4
	when udebtlvl = '15' then 5
	when udebtlvl = '26' then 6
	when udebtlvl = '27' then 7
	when udebtlvl in ('28', '38', '39', '40') then 8
	else null 
end as debt_undergrad,
case
	when gdebtlvl in ('0', '1') then 0
	when gdebtlvl = '11' then 1
	when gdebtlvl = '12' then 2
	when gdebtlvl = '13' then 3
	when gdebtlvl = '14' then 4
	when gdebtlvl = '15' then 5
	when gdebtlvl = '26' then 6
	when gdebtlvl = '27' then 7
	when gdebtlvl in ('28', '38', '39', '40') then 8
	else null 
end as debt_grad
from joined_data;





