with hourly as (

    select
        period_start_at,
        period_start_at::date as recorded_date,
        extract(hour from period_start_at) as hour_of_day,
        avg_demand_mw,
        avg_solar_mw,
        avg_solar_ratio_pct
    from {{ ref('fct_solar_power_hourly') }}

),

dim_date as (

    select
        date_key,
        season,
        is_weekend
    from {{ ref('dim_date') }}

),

dim_time as (

    select
        hour_of_day,
        time_slot_label,
        is_peak_hour
    from {{ ref('dim_time_of_day') }}

),

joined as (

    select
        hourly.recorded_date,
        hourly.hour_of_day,
        dim_date.season,
        dim_date.is_weekend,
        dim_time.time_slot_label,
        dim_time.is_peak_hour,
        hourly.avg_demand_mw,
        hourly.avg_solar_mw,
        hourly.avg_solar_ratio_pct
    from hourly
    inner join dim_date
        on hourly.recorded_date = dim_date.date_key
    inner join dim_time
        on hourly.hour_of_day = dim_time.hour_of_day

)

select * from joined
