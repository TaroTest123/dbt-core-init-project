with source as (

    select
        recorded_date,
        demand_mw,
        solar_mw,
        solar_ratio_pct
    from {{ ref('fct_solar_power') }}

),

with_period as (

    select
        date_trunc('week', recorded_date::date)::date as week_start_date,
        demand_mw,
        solar_mw,
        solar_ratio_pct
    from source

),

aggregated as (

    select
        week_start_date,
        avg(demand_mw) as avg_demand_mw,
        max(demand_mw) as max_demand_mw,
        min(demand_mw) as min_demand_mw,
        avg(solar_mw) as avg_solar_mw,
        max(solar_mw) as max_solar_mw,
        min(solar_mw) as min_solar_mw,
        avg(solar_ratio_pct) as avg_solar_ratio_pct,
        sum(demand_mw * 5.0 / 60) as demand_energy_mwh,
        sum(solar_mw * 5.0 / 60) as solar_energy_mwh,
        count(*) as record_count
    from with_period
    group by week_start_date

),

with_cumulative as (

    select
        *,
        sum(demand_energy_mwh) over (
            partition by date_trunc('year', week_start_date)
            order by week_start_date
        ) as cumulative_demand_energy_mwh,
        sum(solar_energy_mwh) over (
            partition by date_trunc('year', week_start_date)
            order by week_start_date
        ) as cumulative_solar_energy_mwh
    from aggregated

)

select * from with_cumulative
