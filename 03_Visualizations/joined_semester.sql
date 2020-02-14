select
    sed.drf_id,
    cast(sed.phdmonth as int) as phdmonth, 
    cast(sed.phdcy as int) as phdcy, 
    concat(
    	substring(sem.semester, 3, 2),
        case 
	        when right(sem.semester, 3) = 'apr' then 'spr'
	        when right(sem.semester, 3) = 'aug' then 'sum'
	        when right(sem.semester, 3) = 'dec' then 'fal'
	        else ''
        end
    ) as semester,
    sem.modal_funder, 
    sem.modal_suborg,
    cast(case when team_size >= 1 then team_size else 0 end as int) as team_size,
    cast(case when team_size >= 1 then 1 else 0 end as int) as any_federal,
    any_non_federal,
    case when sed.sex = '1' then 'male' else 'female' end as sex,
    case when sed.phdinst in (
	    '104179', '110680', '139658', '141574', '151351', '153658', '155317', '164988',
	    '170976', '201885', '204796', '209542', '214777', '228778', '240444', '243780'
    ) then 1 else 0 end as sequence_data_coverage
from ncses_2019.iris_semester sem
inner join ncses_2019.sed_umetrics_xwalk xw
    on sem.emp_number = xw.emp_number
inner join ncses_2019.nsf_sed sed
    on xw.drf_id = sed.drf_id;

   