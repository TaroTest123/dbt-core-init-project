with solar as (

    select
        recorded_date,
        recorded_time,
        demand_mw,
        solar_mw,
        solar_ratio_pct
    from {{ ref('stg_tokyopower__solar_power') }}

)

select * from solar
