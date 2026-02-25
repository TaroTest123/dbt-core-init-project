with monthly as (

    select
        month_start_date,
        year(month_start_date) as year,
        month(month_start_date) as month,
        avg_demand_mw,
        avg_solar_mw,
        solar_energy_mwh
    from {{ ref('fct_solar_power_monthly') }}

),

daily_counts as (

    select
        date_trunc('month', recorded_date)::date as month_start_date,
        avg(record_count) as avg_daily_record_count
    from {{ ref('fct_solar_power_daily') }}
    group by date_trunc('month', recorded_date)::date

),

with_prev_year as (

    select
        monthly.month_start_date,
        monthly.year,
        monthly.month,
        monthly.avg_demand_mw,
        monthly.avg_solar_mw,
        monthly.solar_energy_mwh,
        lag(monthly.solar_energy_mwh) over (
            partition by monthly.month
            order by monthly.year
        ) as prev_year_solar_energy_mwh,
        daily_counts.avg_daily_record_count
    from monthly
    inner join daily_counts
        on monthly.month_start_date = daily_counts.month_start_date

),

final as (

    select
        month_start_date,
        year,
        month,
        avg_demand_mw,
        avg_solar_mw,
        solar_energy_mwh,
        prev_year_solar_energy_mwh,
        case
            when prev_year_solar_energy_mwh is not null
                and prev_year_solar_energy_mwh > 0
                then round(
                    (solar_energy_mwh - prev_year_solar_energy_mwh)
                    / prev_year_solar_energy_mwh * 100,
                    2
                )
            else null
        end as yoy_solar_change_pct,
        avg_daily_record_count
    from with_prev_year

)

select * from final
