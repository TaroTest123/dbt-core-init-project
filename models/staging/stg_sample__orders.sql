with source as (

    select * from {{ source('sample', 'orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        order_date,
        amount

    from source

)

select * from renamed
