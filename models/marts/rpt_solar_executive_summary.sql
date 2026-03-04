with balance as (

    select
        date_trunc('month', recorded_date)::date as month_start_date,
        avg(avg_demand_mw) as avg_demand_mw,
        avg(avg_solar_mw) as avg_solar_mw,
        sum(demand_energy_mwh) as total_demand_energy_mwh,
        sum(solar_energy_mwh) as total_solar_energy_mwh,
        avg(solar_coverage_pct) as avg_solar_coverage_pct,
        avg(energy_gap_mwh) as avg_energy_gap_mwh,
        count(*) as operating_days
    from {{ ref('fct_demand_supply_balance') }}
    group by date_trunc('month', recorded_date)::date

),

yoy as (

    select
        month_start_date,
        yoy_solar_change_pct
    from {{ ref('fct_solar_power_yoy') }}

),

monthly as (

    select
        month_start_date,
        year(month_start_date) as year,
        month(month_start_date) as month
    from {{ ref('fct_solar_power_monthly') }}

),

kpi_monthly as (

    select
        date_trunc('month', recorded_date)::date as month_start_date,
        sum(estimated_demand_cost_yen) as total_estimated_demand_cost_yen,
        sum(solar_cost_saving_yen) as total_solar_cost_saving_yen,
        sum(grid_co2_emission_t) as total_grid_co2_emission_t,
        sum(solar_co2_avoided_t) as total_solar_co2_avoided_t
    from {{ ref('fct_demand_supply_kpi') }}
    group by date_trunc('month', recorded_date)::date

),

joined as (

    select
        monthly.month_start_date,
        monthly.year,
        monthly.month,
        balance.avg_demand_mw,
        balance.avg_solar_mw,
        balance.total_demand_energy_mwh,
        balance.total_solar_energy_mwh,
        balance.avg_solar_coverage_pct,
        balance.avg_energy_gap_mwh,
        yoy.yoy_solar_change_pct,
        balance.operating_days,
        kpi_monthly.total_estimated_demand_cost_yen,
        kpi_monthly.total_solar_cost_saving_yen,
        kpi_monthly.total_grid_co2_emission_t,
        kpi_monthly.total_solar_co2_avoided_t
    from monthly
    inner join balance
        on monthly.month_start_date = balance.month_start_date
    left join yoy
        on monthly.month_start_date = yoy.month_start_date
    left join kpi_monthly
        on monthly.month_start_date = kpi_monthly.month_start_date

)

select * from joined
