with source as (

    select
        date,
        time,
        demand,
        solar,
        solar_ratio
    from {{ source('tokyopower', 'solar_power') }}
    where date is not null

),

renamed as (

    select
        to_timestamp(date, 'YYYY/MM/DD') as recorded_date,
        time as recorded_time,
        demand as demand_mw,
        solar as solar_mw,
        solar_ratio as solar_ratio_pct
    from source

)

select * from renamed
