with orders as (

    select * from {{ ref('stg_sample__orders') }}

),

final as (

    select
        order_id,
        customer_id,
        order_date,
        amount

    from orders

)

select * from final
