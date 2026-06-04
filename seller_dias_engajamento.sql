WITH params AS (
      SELECT DATE('2018-07-01') AS date_ref
  ),
  dias_vida AS (
        SELECT oi.seller_id,
            -- Quantidade de dias venda nos diferentes períodos
            count(DISTINCT date(o.order_purchase_timestamp)) as dias_vendas_total,
            count(DISTINCT case when date(o.order_purchase_timestamp) >= date_sub(p.date_ref, 28)
                            AND date(o.order_purchase_timestamp) <= p.date_ref
                            THEN date(o.order_purchase_timestamp) END) as dias_vendas_D28,

            count(DISTINCT case when date(o.order_purchase_timestamp) >= date_sub(p.date_ref, 56)
                            AND date(o.order_purchase_timestamp) <= p.date_ref
                            THEN date(o.order_purchase_timestamp) END) as dias_vendas_D56,

            count(DISTINCT case when date(o.order_purchase_timestamp) >= date_sub(p.date_ref, 365)
                            AND date(o.order_purchase_timestamp) <= p.date_ref
                            THEN date(o.order_purchase_timestamp) END) as dias_vendas_D365,

            -- dias sem vendas                
            datediff(p.date_ref, min(date(o.order_purchase_timestamp))) -
            count(DISTINCT date(o.order_purchase_timestamp)) as dias_sem_vendas,

            -- dias com venda / dias sem venda na vida total do seller
            round(coalesce(try_divide(
            count(DISTINCT date(o.order_purchase_timestamp)),

            datediff(p.date_ref, min(date(o.order_purchase_timestamp))) -
            count(DISTINCT date(o.order_purchase_timestamp))), 0), 2) as taxa_engajamento

        FROM olist.orders o
        JOIN olist.order_items oi 
        ON o.order_id = oi.order_id
        CROSS JOIN params p
        WHERE o.order_purchase_timestamp < p.date_ref
        GROUP BY oi.seller_id, p.date_ref
        ORDER BY dias_vendas_total DESC)

  SELECT * FROM dias_vida