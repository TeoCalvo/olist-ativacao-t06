WITH tb_sellers AS (

    SELECT DISTINCT
           oi.seller_id
    FROM workspace.olist.orders o
    INNER JOIN workspace.olist.order_items oi
            ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp < '2018-07-01'
)
-------------------------------------------------------------------------------------------------------
, variaveis_luciano AS (

WITH tb_pedidos AS (
    SELECT *
    FROM workspace.olist.orders
    WHERE order_purchase_timestamp < '2018-07-01'
), -- aqui eu crio a tabela de pedidos filtrados antes do hoje.

tb_vendas AS (
    SELECT DISTINCT
           oi.seller_id,
           o.order_id,
           DATE(o.order_purchase_timestamp) AS dtVenda
    FROM tb_pedidos o
    INNER JOIN workspace.olist.order_items oi
        ON o.order_id = oi.order_id
), -- aqui eu crio a tabela de vendas filtradas antes do hoje.

tb_intervalos AS (
    SELECT
        seller_id,
        dtVenda,
        LAG(dtVenda) OVER (
            PARTITION BY seller_id
            ORDER BY dtVenda
        ) AS dtVendaAnterior
    FROM tb_vendas
),

tb_dias_entre_vendas AS (
    SELECT
        seller_id,
        DATEDIFF(
            day,
            dtVendaAnterior,
            dtVenda
        ) AS vlDiasEntreVendas
    FROM tb_intervalos
    WHERE dtVendaAnterior IS NOT NULL
)

SELECT
    seller_id,

    AVG(vlDiasEntreVendas) AS vlDiasEntreVendasMedio,

    MIN(vlDiasEntreVendas) AS vlDiasEntreVendasMin,
    
    MAX(vlDiasEntreVendas) AS vlDiasEntreVendasMax,

    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP25,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP50,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY vlDiasEntreVendas)
        AS vlDiasEntreVendasP75

FROM tb_dias_entre_vendas
GROUP BY seller_id
)
----------------------------------------------------------------------------------------------------------

, variaveis_ana_paula AS (
WITH tb_data AS (
    SELECT date('2018-07-01') as dt_referencia
),
tb_pedidos AS (
  SELECT *
  FROM workspace.olist.orders
  CROSS JOIN tb_data d
  WHERE order_purchase_timestamp < dt_referencia
),
tb_seller_rfv AS (
    select  
        i.seller_id,
        count(distinct p.order_id) as qtdPedidosVida,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosD28,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosD56,
        count(distinct case 
                        when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosD365,
        count(distinct case 
                        when order_status = 'delivered' 
                        then p.order_id end) as qtdPedidosDeliveredVida,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosDeliveredD28,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosDeliveredD56,
        count(distinct case 
                        when order_status = 'delivered' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosDeliveredD365,
        count(distinct case 
                        when order_status = 'invoiced' 
                        then p.order_id end) as qtdPedidosInvoicedVida,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosInvoicedD28,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosInvoicedD56,
        count(distinct case 
                        when order_status = 'invoiced' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosInvoicedD365,
        count(distinct case 
                        when order_status = 'shipped' 
                        then p.order_id end) as qtdPedidosShippedVida,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosShippedD28,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosShippedD56,
        count(distinct case 
                        when order_status = 'shipped' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosShippedD365,
        count(distinct case 
                        when order_status = 'processing' 
                        then p.order_id end) as qtdPedidosProcessingVida,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosProcessingD28,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosProcessingD56,
        count(distinct case 
                        when order_status = 'processing' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosProcessingD365,
        count(distinct case 
                        when order_status = 'unavailable' 
                        then p.order_id end) as qtdPedidosUnavailableVida,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosUnavailableD28,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosUnavailableD56,
        count(distinct case 
                        when order_status = 'unavailable' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosUnavailableD365,
        count(distinct case 
                        when order_status = 'canceled' 
                        then p.order_id end) as qtdPedidosCanceledVida,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosCanceledD28,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosCanceledD56,
        count(distinct case 
                        when order_status = 'canceled' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosCanceledD365,
        count(distinct case 
                        when order_status = 'created' 
                        then p.order_id end) as qtdPedidosCreatedVida,
         count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosCreatedD28,
        count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosCreatedD56,
        count(distinct case 
                        when order_status = 'created' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosCreatedD365,
        count(distinct case 
                        when order_status = 'approved' 
                        then p.order_id end) as qtdPedidosApprovedVida,
         count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                        then p.order_id end) as qtdPedidosApprovedD28,
        count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                        then p.order_id end) as qtdPedidosApprovedD56,
        count(distinct case 
                        when order_status = 'approved' and datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                        then p.order_id end) as qtdPedidosApprovedD365,
        count(i.product_id) as qtdItensVendaVida,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 28 
                then i.product_id end) as qtdItensVendaD28,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 56 
                then i.product_id end) as qtdItensVendaD56,
        count(case 
                when datediff(d.dt_referencia, p.order_purchase_timestamp) <= 365 
                then i.product_id end) as qtdItensVendaD365,
        min(date_diff(d.dt_referencia, p.order_purchase_timestamp)) as diasDesdeUltimaVenda,
        max(date_diff(d.dt_referencia, p.order_purchase_timestamp)) as diasDesdePrimeiraVenda       
                          
    from tb_pedidos p
    join workspace.olist.order_items i on p.order_id = i.order_id
    cross join tb_data d
    group by i.seller_id 
)
SELECT * FROM tb_seller_rfv
)

-----------------------------------------------------------------------------------------------------
, variaveis_ana_c AS (
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
)

-----------------------------------------------------------------------------------------------------------------------------

, variaveis_lili_1 AS (
WITH params AS (
    SELECT
        DATE('2018-07-01') AS date_ref,
        DATE_ADD(DATE('2018-07-01'), 28) AS periodo
), 

periodo as (
SELECT DISTINCT
    s.seller_id,
    i.order_id
FROM olist.sellers s
LEFT JOIN workspace.olist.order_items i on s.seller_id = i.seller_id
LEFT JOIN olist.orders o on i.order_id = o.order_id
CROSS JOIN params p
WHERE o.order_purchase_timestamp BETWEEN p.date_ref AND p.periodo
),

periodo_vendas as (
SELECT 
    seller_id,
    COUNT(*) as total_pedidos_periodo
FROM periodo
GROUP BY seller_id),

vendas as (
SELECT DISTINCT
    s.seller_id,
    i.order_id
FROM olist.sellers s
LEFT JOIN workspace.olist.order_items i on s.seller_id = i.seller_id
LEFT JOIN olist.orders o on i.order_id = o.order_id
CROSS JOIN params p
WHERE o.order_purchase_timestamp < p.date_ref
),

total_vendas as (
    SELECT 
    seller_id,
    COUNT(*) as total_pedidos
FROM vendas
GROUP BY seller_id
)

select 
    t.seller_id,
    round(total_pedidos_periodo/total_pedidos,2) as prop_pedidos_periodo
from total_vendas t
inner join periodo_vendas p on t.seller_id = p.seller_id
)

------------------------------------------------------------------------------------------------------
, variaveis_lili_2 AS (
WITH params AS (
    SELECT DATE('2018-07-01') AS date_ref
)

SELECT 
    s.seller_id,

    round(COALESCE(
        TRY_DIVIDE(
            COUNT(DISTINCT o.order_purchase_timestamp),
            DATEDIFF(
                p.date_ref,
                MIN(DATE(o.order_purchase_timestamp))
            )
        ),
        0
    ),2) AS ativacao_por_dia

FROM olist.sellers s
CROSS JOIN params p
LEFT JOIN workspace.olist.order_items i 
    ON s.seller_id = i.seller_id
LEFT JOIN olist.orders o 
    ON i.order_id = o.order_id
WHERE o.order_purchase_timestamp < p.date_ref
GROUP BY s.seller_id, p.date_ref
)

-----------------------------------------------------------------------------------------------
, variaveis_jussara AS (
WITH tb_pedidos AS (
    SELECT
        *
    FROM workspace.olist.orders
    WHERE order_purchase_timestamp < '2018-07-01'
),
tb_pedidos_seller AS (
    SELECT p.order_id,
        DATE(p.order_purchase_timestamp) as order_purchase_timestamp,
        i.seller_id,
        sum(i.price) as receita
    FROM tb_pedidos AS p
    INNER
    JOIN workspace.olist.order_items AS i
        ON p.order_id = i.order_id
    GROUP 
      BY 1,2,3
),
tb_intervalos AS (
    SELECT
        DATE '2018-07-01' AS DTLIMITE,
        DATE '2018-07-01' - INTERVAL '28' DAY AS D28,
        DATE '2018-07-01' - INTERVAL '56' DAY AS D56,
        DATE '2018-07-01' - INTERVAL '365' DAY AS D365
),
tb_seller_rfv AS (
    SELECT
        ps.seller_id,
        -- Receita por período
        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D28 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) AS vlReceitaP28,

        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D56 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) AS vlReceitaP56,

        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D365 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) AS vlReceitaP365,

        -- Ticket médio = receita / número de pedidos
        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D28 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) /
        NULLIF(
            COUNT(
                CASE
                    WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D28 AND inter.DTLIMITE
                    THEN ps.order_id
                    ELSE NULL
                END
            ),
            0
        ) AS vlTicketMedioP28,

        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D56 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) /
        NULLIF(
            COUNT(
                CASE
                    WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D56 AND inter.DTLIMITE
                    THEN ps.order_id
                    ELSE NULL
                END
            ),
            0
        ) AS vlTicketMedioP56,

        SUM(
            CASE
                WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D365 AND inter.DTLIMITE
                THEN ps.receita
                ELSE 0
            END
        ) /
        NULLIF(
            COUNT(
                CASE
                    WHEN DATE(ps.order_purchase_timestamp) BETWEEN inter.D365 AND inter.DTLIMITE
                    THEN ps.order_id
                    ELSE NULL
                END
            ),
            0
        ) AS vlTicketMedioP365

    FROM tb_pedidos_seller AS ps
    CROSS JOIN tb_intervalos AS inter
    GROUP BY ps.seller_id
)
SELECT *
FROM tb_seller_rfv
     
)


--------------------------------------------------------------------------------------------------------------

SELECT
    s.*,

    vl.* EXCEPT(seller_id),
    vap.* EXCEPT(seller_id),
    vac.* EXCEPT(seller_id),
    vl1.* EXCEPT(seller_id),
    vl2.* EXCEPT(seller_id),
    vj.* EXCEPT(seller_id)

FROM tb_sellers s

LEFT JOIN variaveis_luciano vl
       ON s.seller_id = vl.seller_id

LEFT JOIN variaveis_ana_paula vap
       ON s.seller_id = vap.seller_id

LEFT JOIN variaveis_ana_c vac
       ON s.seller_id = vac.seller_id

LEFT JOIN variaveis_lili_1 vl1
       ON s.seller_id = vl1.seller_id

LEFT JOIN variaveis_lili_2 vl2
       ON s.seller_id = vl2.seller_id

LEFT JOIN variaveis_jussara vj
       ON s.seller_id = vj.seller_id
;