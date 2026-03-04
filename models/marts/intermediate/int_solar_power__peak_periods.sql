with hourly as (

    select
        period_start_at::date as recorded_date,
        extract(hour from period_start_at) as hour_of_day,
        avg_demand_mw,
        avg_solar_mw
    from {{ ref('fct_solar_power_hourly') }}

),

daily as (

    select
        recorded_date
    from {{ ref('fct_solar_power_daily') }}

),

demand_peak as (

    select
        recorded_date,
        hour_of_day as peak_demand_hour,
        avg_demand_mw as peak_demand_mw
    from (
        select
            recorded_date,
            hour_of_day,
            avg_demand_mw,
            row_number() over (
                partition by recorded_date
                order by avg_demand_mw desc
            ) as rn
        from hourly
    )
    where rn = 1

),

solar_peak as (

    select
        recorded_date,
        hour_of_day as peak_solar_hour,
        avg_solar_mw as peak_solar_mw
    from (
        select
            recorded_date,
            hour_of_day,
            avg_solar_mw,
            row_number() over (
                partition by recorded_date
                order by avg_solar_mw desc
            ) as rn
        from hourly
    )
    where rn = 1

),

demand_min as (

    select
        recorded_date,
        hour_of_day as min_demand_hour,
        avg_demand_mw as min_demand_mw
    from (
        select
            recorded_date,
            hour_of_day,
            avg_demand_mw,
            row_number() over (
                partition by recorded_date
                order by avg_demand_mw asc
            ) as rn
        from hourly
    )
    where rn = 1

),

joined as (

    select
        daily.recorded_date,
        demand_peak.peak_demand_hour,
        demand_peak.peak_demand_mw,
        solar_peak.peak_solar_hour,
        solar_peak.peak_solar_mw,
        demand_min.min_demand_hour,
        demand_min.min_demand_mw
    from daily
    inner join demand_peak
        on daily.recorded_date = demand_peak.recorded_date
    inner join solar_peak
        on daily.recorded_date = solar_peak.recorded_date
    inner join demand_min
        on daily.recorded_date = demand_min.recorded_date

)

select * from joined
