with demand_supply as (

    select
        recorded_date,
        demand_energy_mwh,
        solar_energy_mwh,
        energy_gap_mwh
    from {{ ref('fct_demand_supply_balance') }}

),

electricity_rate as (

    select
        fiscal_year,
        electricity_rate_yen_per_kwh
    from {{ ref('seed_electricity_rate') }}

),

co2_factor as (

    select
        fiscal_year,
        co2_factor_t_per_kwh
    from {{ ref('seed_co2_emission_factor') }}

),

joined as (

    select
        ds.recorded_date,
        ds.demand_energy_mwh,
        ds.solar_energy_mwh,
        ds.energy_gap_mwh,
        er.electricity_rate_yen_per_kwh,
        cf.co2_factor_t_per_kwh,
        round(ds.demand_energy_mwh * 10000 * er.electricity_rate_yen_per_kwh, 2) as estimated_demand_cost_yen,
        round(ds.solar_energy_mwh * 10000 * er.electricity_rate_yen_per_kwh, 2) as solar_cost_saving_yen,
        round(ds.energy_gap_mwh * 10000 * cf.co2_factor_t_per_kwh, 4) as grid_co2_emission_t,
        round(ds.solar_energy_mwh * 10000 * cf.co2_factor_t_per_kwh, 4) as solar_co2_avoided_t
    from demand_supply as ds
    inner join electricity_rate as er
        on year(ds.recorded_date) = er.fiscal_year
    inner join co2_factor as cf
        on year(ds.recorded_date) = cf.fiscal_year

)

select * from joined
