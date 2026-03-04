with daily as (

    select
        recorded_date,
        avg_demand_mw,
        avg_solar_mw,
        demand_energy_mwh,
        solar_energy_mwh
    from {{ ref('fct_solar_power_daily') }}

),

peak_periods as (

    select
        recorded_date,
        peak_demand_hour,
        peak_solar_hour,
        peak_demand_mw,
        peak_solar_mw
    from {{ ref('int_solar_power__peak_periods') }}

),

dim_date as (

    select
        date_key,
        season,
        is_weekend
    from {{ ref('dim_date') }}

),

joined as (

    select
        daily.recorded_date,
        dim_date.season,
        dim_date.is_weekend,
        daily.avg_demand_mw,
        daily.avg_solar_mw,
        daily.demand_energy_mwh,
        daily.solar_energy_mwh,
        case
            when daily.demand_energy_mwh > 0
                then round(daily.solar_energy_mwh / daily.demand_energy_mwh * 100, 2)
            else 0
        end as solar_coverage_pct,
        daily.demand_energy_mwh - daily.solar_energy_mwh as energy_gap_mwh,
        peak_periods.peak_demand_hour,
        peak_periods.peak_solar_hour,
        abs(peak_periods.peak_demand_hour - peak_periods.peak_solar_hour) as peak_gap_hours
    from daily
    inner join peak_periods
        on daily.recorded_date = peak_periods.recorded_date
    inner join dim_date
        on daily.recorded_date = dim_date.date_key

)

select * from joined
