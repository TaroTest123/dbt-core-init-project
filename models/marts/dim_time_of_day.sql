with hourly as (

    select distinct
        extract(hour from period_start_at) as hour_of_day
    from {{ ref('fct_solar_power_hourly') }}

),

time_attributes as (

    select
        hour_of_day,
        case
            when hour_of_day between 5 and 6 then '早朝'
            when hour_of_day between 7 and 9 then '朝'
            when hour_of_day between 10 and 12 then '昼'
            when hour_of_day between 13 and 15 then '午後'
            when hour_of_day between 16 and 18 then '夕方'
            else '夜'
        end as time_slot_label,
        case
            when hour_of_day between 9 and 20 then true
            else false
        end as is_peak_hour,
        case
            when hour_of_day between 6 and 18 then true
            else false
        end as is_solar_hour
    from hourly

)

select * from time_attributes
