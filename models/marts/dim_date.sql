with daily as (

    select
        recorded_date
    from {{ ref('fct_solar_power_daily') }}

),

date_attributes as (

    select
        recorded_date as date_key,
        year(recorded_date) as year,
        quarter(recorded_date) as quarter,
        month(recorded_date) as month,
        monthname(recorded_date) as month_name,
        weekofyear(recorded_date) as week_of_year,
        dayofweek(recorded_date) as day_of_week,
        dayname(recorded_date) as day_name,
        case
            when dayofweek(recorded_date) in (0, 6) then true
            else false
        end as is_weekend,
        case
            when month(recorded_date) in (3, 4, 5) then '春'
            when month(recorded_date) in (6, 7, 8) then '夏'
            when month(recorded_date) in (9, 10, 11) then '秋'
            else '冬'
        end as season
    from daily

)

select * from date_attributes
