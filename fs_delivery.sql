WITH tb_pedidos AS (
  SELECT *
  FROM workspace.olist.orders o
  INNER JOIN workspace.olist.order_items oi on o.order_id = oi.order_id
  WHERE order_purchase_timestamp <= '{date}'
),

tb_final AS (

    SELECT seller_id AS idSeller,

        -- Percentual do valor do frete em relação ao produto - Vida
        coalesce(sum(freight_value) / sum(price) * 100, 0) as pctFretePedVida,

        -- Percentual do valor do frete em relação ao produto - 28 dias
        coalesce(sum(case when order_purchase_timestamp >= date('{date}') - interval '28 days' then freight_value end) / sum(case when order_purchase_timestamp >= date('{date}') - interval '28 days' then price end) * 100, 0) as pctFretePed28d,

        -- Percentual do valor do frete em relação ao produto - 56 dias
        coalesce(sum(case when order_purchase_timestamp >= date('{date}') - interval '56 days' then freight_value end) / sum(case when order_purchase_timestamp >= date('{date}') - interval '56 days' then price end), 0) * 100 as pctFretePed56d,

        -- Percentual do valor do frete em relação ao produto - 365 dias
        coalesce(sum(case when order_purchase_timestamp >= date('{date}') - interval '365 days' then freight_value end) / sum(case when order_purchase_timestamp >= date('{date}') - interval '365 days' then price end), 0) * 100 as pctFretePed365d,

        -- Média do valor do frete - Vida
        coalesce(avg(freight_value), 0) as avgFreteVida,

        -- Média do valor do frete - 28 dias
        coalesce(avg(case when order_purchase_timestamp >= date('{date}') - interval '28 days' then freight_value end), 0) as avgFrete28d,

        -- Média do valor do frete - 56 dias
        coalesce(avg(case when order_purchase_timestamp >= date('{date}') - interval '56 days' then freight_value end), 0) as avgFrete56d,

        -- Média do valor do frete - 365 dias
        coalesce(avg(case when order_purchase_timestamp >= date('{date}') - interval '365 days' then freight_value end), 0) as avgFrete365d,

        -- SLA de entrega
        coalesce(avg(date_diff(order_estimated_delivery_date, order_approved_at)), 0) as avgSlaEntrega,

        -- Tempo médio de entrega do pedido
        coalesce(avg(date_diff(order_delivered_customer_date, order_approved_at)), 0) as avgEntrega,

        -- Tempo médio de transporte do pedido
        coalesce(avg(date_diff(order_delivered_customer_date, order_delivered_carrier_date)), 0) as avgTranspPed,

        -- Número de pedidos atrasados
        coalesce(count(case when date_diff(order_estimated_delivery_date, order_delivered_customer_date)> 0 then 1 end), 0) as nPedAtrasados,

        -- Percentual de pedidos atrasados - Vida
        coalesce(count(case when date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then 1 end) / count(*) * 100, 0) as pctPedAtrasadosVida,

        -- Percentual de pedidos atrasados - 28 dias
        coalesce(count(case when order_purchase_timestamp >= date('{date}') - interval '28 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then 1 end) / nullif(count(case when order_purchase_timestamp >= date('{date}') - interval '28 days' then 1 end), 0) * 100, 0) as pctPedAtrasados28d,

        -- Percentual de pedidos atrasados - 56 dias
        coalesce(count(case when order_purchase_timestamp >= date('{date}') - interval '56 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then 1 end) / nullif(count(case when order_purchase_timestamp >= date('{date}') - interval '56 days' then 1 end), 0) * 100, 0) as pctPedAtrasados56d,

        -- Percentual de pedidos atrasados - 365 dias
        coalesce(count(case when order_purchase_timestamp >= date('{date}') - interval '365 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then 1 end) / nullif(count(case when order_purchase_timestamp >= date('{date}') - interval '365 days' then 1 end), 0) * 100, 0) as pctPedAtrasados365d,

        -- Tempo médio de entrega dos pedidos atrasados - Vida
        coalesce(avg(case when date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then date_diff(order_estimated_delivery_date, order_delivered_customer_date) end), 0) as avgEntregaPedAtrasadosVida,

        -- Tempo médio de entrega dos pedidos atrasados - 28 dias
        coalesce(avg(case when order_purchase_timestamp >= date('{date}') - interval '28 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then date_diff(order_estimated_delivery_date, order_delivered_customer_date) end), 0) as avgEntregaPedAtrasados28d,

        -- Tempo médio de entrega dos pedidos atrasados - 56 dias
        coalesce(avg(case when order_purchase_timestamp >= date('{date}') - interval '56 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then date_diff(order_estimated_delivery_date, order_delivered_customer_date) end), 0) as avgEntregaPedAtrasados56d,

        -- Tempo médio de entrega dos pedidos atrasados - 365 dias
        coalesce(avg(case when order_purchase_timestamp >= date( '{date}') - interval '365 days' and date_diff(order_estimated_delivery_date, order_delivered_customer_date) > 0 then date_diff(order_estimated_delivery_date, order_delivered_customer_date) end), 0) as avgEntregaPedAtrasados365d,

        -- Diferença média percentual(25%, 50%, 75%) entre a data de entrega estimada e data de entrega
        -- 25%
        percentile_cont(0.25) within group (order by date_diff(order_estimated_delivery_date, order_delivered_customer_date)) as diffEntregaPed25p,

        -- 50%
        percentile_cont(0.50) within group (order by date_diff(order_estimated_delivery_date, order_delivered_customer_date)) as diffEntregaPed50p,

        -- 75%
        percentile_cont(0.75) within group (order by date_diff(order_estimated_delivery_date, order_delivered_customer_date)) as diffEntregaPed75p,    

        -- Tempo Limite vendedor = shipping_limit_date - order_approved_at
        coalesce(avg(date_diff(shipping_limit_date, order_approved_at)), 0) as avgTempoLimiteVendedor,

        -- Tempo Atraso vendedor = order_delivered_carrier_date - shipping_limit_date
        coalesce(avg(date_diff(order_delivered_carrier_date, shipping_limit_date)), 0) as avgTempoAtrasoVendedor,

        -- Tempo transportadora = order_delivered_customer_date - order_delivered_carrier_date
        coalesce(avg(date_diff(order_delivered_customer_date, order_delivered_carrier_date)), 0) as avgTempoTransportadora,

        -- Consistencia = (STDDEV(dias_despacho) / AVG (dias_despacho)
        coalesce(stddev(date_diff(order_estimated_delivery_date, order_delivered_customer_date)) / nullif(avg(date_diff(order_estimated_delivery_date, order_delivered_customer_date)),0), 0) as vlConsistencia

    FROM tb_pedidos
    GROUP BY seller_id
    ORDER BY seller_id

)

SELECT '{date}' AS dtRef,
        *

FROM tb_final