-- combining datasets

create table gms_project.data_combined as (

select * from gms_project.data_10
union all
select * from gms_project.data_11
union all
select * from gms_project.data_12

);

-- data exploration

select * from gms_project.data_combined
limit 5;

select
count(*) as total_rows,
count(visitid) as non_null_rows
from gms_project.data_combined;

select
	visitid,
    count(*) as total_rows
from gms_project.data_combined
group by 1
having count(*) > 1
limit 5;

select
	fullvisitorid,
    count(*) as total_rows
from gms_project.data_combined
group by 1
having count(*) > 1
limit 5;

select
	concat(fullvisitorid, '-', visitid) as unique_session_id,
    count(*) as total_rows
from gms_project.data_combined
group by 1
having count(*) > 1
limit 5;

select
	concat(fullvisitorid, '-', visitid) as unique_session_id,
    from_unixtime(date) + interval -8 hour as date,
    count(*) as total_rows
from gms_project.data_combined
group by 1, 2
having unique_session_id = '4961200072408009421-1480578925'
limit 5;

select
	concat(fullvisitorid, '-', visitid) as unique_session_id,
    from_unixtime(date) + interval -7 hour as date,
    count(*) as total_rows
from gms_project.data_combined
group by 1, 2
having unique_session_id = '0368176022600320212-1477983528'
limit 5;

-- Website Engagement by Day

select
	date,
    count(distinct unique_session_id) as sessions
from (
	select
        date(from_unixtime(date)) as date,
		concat(fullvisitorid, '-', visitid) as unique_session_id
    from gms_project.data_combined
    group by 1,2
    ) t1
    Group by 1
    order by 1;

select
	dayname(date) as weekday, 
    count(distinct unique_session_id) as sessions
from (
	select
        date(from_unixtime(date)) as date,
		concat(fullvisitorid, '-', visitid) as unique_session_id
    from gms_project.data_combined
    group by 1,2
    ) t1
    Group by 1
    order by 2 desc;

-- Website Engagement & Monetization by Day

select
	dayname(date) as weekday, 
    count(distinct unique_session_id) as sessions,
    sum(converted) as conversions,
    ((sum(converted)/count(distinct unique_session_id)) * 100) as conversion_rate
from (
	select
        date(from_unixtime(date)) as date,
        case
			when transactions >= 1 then 1
            else 0
		end as converted,
		concat(fullvisitorid, '-', visitid) as unique_session_id
    from gms_project.data_combined
    group by 1,2,3
    ) t1
    Group by 1
    order by 2 desc;
    
-- Website Engagement & Monetization by Device
    
select
	deviceCategory,
    count(distinct unique_session_id) as sessions,
    ((count(distinct unique_session_id)/sum(count(distinct unique_session_id)) over ())*100) as sessions_percentage,
    sum(transactionrevenue)/1e6 as revenue,
    ((sum(transactionrevenue)/sum(sum(transactionrevenue)) over ())*100) as revenue_percentage
from (
	select
		deviceCategory,
        transactionrevenue,
		concat(fullvisitorid, '-', visitid) as unique_session_id
    from gms_project.data_combined
    group by 1,2,3
    ) t1
    Group by 1;
    
-- Website Engagement & Monetization by Region

select
	deviceCategory,
    region,
    count(distinct unique_session_id) as sessions,
    ((count(distinct unique_session_id)/sum(count(distinct unique_session_id)) over ())*100) as sessions_percentage,
    sum(transactionrevenue)/1e6 as revenue,
    ((sum(transactionrevenue)/sum(sum(transactionrevenue)) over ())*100) as revenue_percentage
from (
	select
		deviceCategory,
        case
        when region = '' or region is null then 'na'
        else region 
        end as region,
        transactionrevenue,
		concat(fullvisitorid, '-', visitid) as unique_session_id
    from gms_project.data_combined
    where deviceCategory = 'mobile'
    group by 1,2,3,4
    ) t1
    Group by 1,2
    order by 3 desc;
    
-- Website Retention

select
	case
    when newVisits = 1 then 'New Visitor'
    else 'Returning visitor'
    end as visitor_type,
    count(distinct fullvisitorid) as visitors,
    ((count(distinct fullvisitorid)/sum(count(distinct fullvisitorid)) over ())*100) as visitor_percentage
from gms_project.data_combined
group by 1;

-- Website Acquisition

select
	count(distinct unique_session_id) as sessions,
    sum(bounces) as bounces,
    ((sum(bounces)/count(distinct unique_session_id))*100) as bounce_rate
from (
	select
		bounces,
        concat(fullvisitorid, '-', visitid) as unique_session_id
	from gms_project.data_combined
    group by 1,2
    ) t1
    order by 1 desc;
    
-- Website Acquisition by Channel

 select
	channelGrouping,
	count(distinct unique_session_id) as sessions,
    sum(bounces) as bounces,
    ((sum(bounces)/count(distinct unique_session_id))*100) as bounce_rate
from (
	select
		channelGrouping,
		bounces,
        concat(fullvisitorid, '-', visitid) as unique_session_id
	from gms_project.data_combined
    group by 1,2,3
    ) t1
    group by 1 
    order by 2 desc;

-- Website Acquisition & Monetization by Channel
select
	channelGrouping,
    count(distinct unique_session_id) as sessions,
    sum(bounces) as bounces,
    ((sum(bounces)/count(distinct unique_session_id))*100) as bounce_rate,
    (sum(pageviews)/count(distinct unique_session_id)) as avg_pagesonsite,
    (sum(timeonsite)/count(distinct unique_session_id)) as avg_timeonsite,
    sum(case when transactions >= 1 then 1 else 0 end) as conversions,
    ((sum(case when transactions >= 1 then 1 else 0 end)/count(distinct unique_session_id))*100) as conversion_rate,
    sum(transactionrevenue)/1e6 as revenue
from (
	select
		channelGrouping,
        bounces,
        pageviews,
        timeonsite,
        transactions,
        transactionrevenue,
        concat(fullvisitorid, '-', visitid) as unique_session_id
	from gms_project.data_combined
    group by 1,2,3,4,5,6,7
    ) t1
group by 1
order by 2 desc;


