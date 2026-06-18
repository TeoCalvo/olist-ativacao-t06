-- SQL Refatorado para Databricks
-- Objetivo: menos CTEs intermediarias, sem repeticao de código
-- Padronizacao: nomes de variaveis mantidos, calculos de intervalo com CASE WHEN inline
-- Data de referencia: {date}
WITH base_sellers AS (
    -- CTE base unica: sellers ativos com pedidos antes da data de referencia
    SELECT DISTINCT oi.seller_id
    FROM workspace.olist.orders o
    INNER JOIN workspace.olist.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp < '{date}'
),

base_pedidos_vendas AS (
    -- CTE unica com todos pedidos e vendas filtradas antes da data de referencia
    SELECT 
        o.order_id,
        oi.seller_id,
        oi.product_id,
        oi.price,
        o.order_status,
        DATE(o.order_purchase_timestamp) AS dtVenda,
        o.order_purchase_timestamp
    FROM workspace.olist.orders o
    INNER JOIN workspace.olist.order_items oi ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp < '{date}'
),

base_com_venda_anterior AS (
    -- CTE minima so para Luciano: adiciona dtVendaAnterior com window function
    SELECT 
        seller_id,
        order_id,
        product_id,
        price,
        order_status,
        dtVenda,
        order_purchase_timestamp,
        LAG(dtVenda) OVER (PARTITION BY seller_id ORDER BY dtVenda) AS dtVendaAnterior
    FROM base_pedidos_vendas
),

tb_final AS (

SELECT
    bs.seller_id AS idSeller,

    -- ============================================
    -- variaveis_luciano: Dias entre vendas (stats)
    -- ============================================
    ROUND(AVG(
        CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ), 2) AS vlDiasEntreVendasMedio,

    MIN(
        CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ) AS vlDiasEntreVendasMin,

    MAX(
        CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ) AS vlDiasEntreVendasMax,

    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ) AS vlDiasEntreVendasP25,

    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ) AS vlDiasEntreVendasP50,

    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY CASE 
            WHEN bcv.dtVendaAnterior IS NOT NULL THEN DATEDIFF(day, bcv.dtVendaAnterior, bcv.dtVenda)
            ELSE NULL
        END
    ) AS vlDiasEntreVendasP75,

    -- ============================================
    -- variaveis_ana_paula: Qtd pedidos por período e status
    -- ============================================
    COUNT(DISTINCT bcv.order_id) AS qtdPedidosVida,

    COUNT(DISTINCT CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosD28,

    COUNT(DISTINCT CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosD56,

    COUNT(DISTINCT CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosD365,

    -- Delivered
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'delivered' THEN bcv.order_id END) AS qtdPedidosDeliveredVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'delivered' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosDeliveredD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'delivered' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosDeliveredD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'delivered' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosDeliveredD365,

    -- Invoiced
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'invoiced' THEN bcv.order_id END) AS qtdPedidosInvoicedVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'invoiced' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosInvoicedD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'invoiced' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosInvoicedD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'invoiced' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosInvoicedD365,

    -- Shipped
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'shipped' THEN bcv.order_id END) AS qtdPedidosShippedVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'shipped' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosShippedD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'shipped' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosShippedD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'shipped' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosShippedD365,

    -- Processing
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'processing' THEN bcv.order_id END) AS qtdPedidosProcessingVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'processing' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosProcessingD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'processing' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosProcessingD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'processing' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosProcessingD365,

    -- Unavailable
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'unavailable' THEN bcv.order_id END) AS qtdPedidosUnavailableVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'unavailable' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosUnavailableD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'unavailable' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosUnavailableD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'unavailable' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosUnavailableD365,

    -- Canceled
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'canceled' THEN bcv.order_id END) AS qtdPedidosCanceledVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'canceled' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosCanceledD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'canceled' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosCanceledD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'canceled' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosCanceledD365,

    -- Created
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'created' THEN bcv.order_id END) AS qtdPedidosCreatedVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'created' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosCreatedD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'created' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosCreatedD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'created' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosCreatedD365,

    -- Approved
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'approved' THEN bcv.order_id END) AS qtdPedidosApprovedVida,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'approved' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 
                        THEN bcv.order_id END) AS qtdPedidosApprovedD28,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'approved' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 
                        THEN bcv.order_id END) AS qtdPedidosApprovedD56,
    COUNT(DISTINCT CASE WHEN bcv.order_status = 'approved' AND DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 
                        THEN bcv.order_id END) AS qtdPedidosApprovedD365,

    COUNT(bcv.product_id) AS qtdItensVendaVida,
    COUNT(CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 28 THEN bcv.product_id END) AS qtdItensVendaD28,
    COUNT(CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 56 THEN bcv.product_id END) AS qtdItensVendaD56,
    COUNT(CASE WHEN DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}')) <= 365 THEN bcv.product_id END) AS qtdItensVendaD365,

    MIN(DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}'))) AS diasDesdeUltimaVenda,
    MAX(DATEDIFF(day, bcv.order_purchase_timestamp, DATE('{date}'))) AS diasDesdePrimeiraVenda,

    -- ============================================
    -- variaveis_ana_c: Dias com venda e engajamento
    -- ============================================
    COUNT(DISTINCT bcv.dtVenda) AS qtdDiasVendastotal,

    COUNT(DISTINCT CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 28) AND bcv.dtVenda <= DATE('{date}')
                        THEN bcv.dtVenda END) AS qtdDiasVendasD28,

    COUNT(DISTINCT CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 56) AND bcv.dtVenda <= DATE('{date}')
                        THEN bcv.dtVenda END) AS qtdDiasVendasD56,

    COUNT(DISTINCT CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 365) AND bcv.dtVenda <= DATE('{date}')
                        THEN bcv.dtVenda END) AS qtdDiasVendasD365,

    DATEDIFF(DATE('{date}'), MIN(bcv.dtVenda)) - COUNT(DISTINCT bcv.dtVenda) AS qtdDiasSemVendas,

    ROUND(COALESCE(TRY_DIVIDE(
        COUNT(DISTINCT bcv.dtVenda),
        DATEDIFF(DATE('{date}'), MIN(bcv.dtVenda)) - COUNT(DISTINCT bcv.dtVenda)
    ), 0), 2) AS txEngajamento,

    -- ============================================
    -- variaveis_lili_1: Proporção de pedidos no período (future window)
    -- ============================================
    ROUND(
        TRY_DIVIDE(
            COUNT(DISTINCT CASE WHEN bcv.dtVenda >= DATE('{date}') AND bcv.dtVenda <= DATE_ADD(DATE('{date}'), 28)
                                THEN bcv.order_id END),
            COUNT(DISTINCT bcv.order_id)
        ),
        2
    ) AS txPropPedidosPeriodo,

    -- ============================================
    -- variaveis_lili_2: Ativação por dia
    -- ============================================
    ROUND(COALESCE(
        TRY_DIVIDE(
            COUNT(DISTINCT bcv.order_purchase_timestamp),
            DATEDIFF(DATE('{date}'), MIN(DATE(bcv.order_purchase_timestamp)))
        ),
        0
    ), 2) AS txAtivacaoPorDia,

    -- ============================================
    -- variaveis_jussara: Receita e ticket médio por período
    -- ============================================
    SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 28) AND bcv.dtVenda <= DATE('{date}')
             THEN bcv.price ELSE 0 END) AS vlReceitaD28,

    SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 56) AND bcv.dtVenda <= DATE('{date}')
             THEN bcv.price ELSE 0 END) AS vlReceitaD56,

    SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 365) AND bcv.dtVenda <= DATE('{date}')
             THEN bcv.price ELSE 0 END) AS vlReceitaD365,

    ROUND(SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 28) AND bcv.dtVenda <= DATE('{date}')
                   THEN bcv.price ELSE 0 END) / 
          NULLIF(COUNT(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 28) AND bcv.dtVenda <= DATE('{date}')
                            THEN bcv.order_id ELSE NULL END), 0), 2) AS vlTicketMedioD28,

    ROUND(SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 56) AND bcv.dtVenda <= DATE('{date}')
                   THEN bcv.price ELSE 0 END) / 
          NULLIF(COUNT(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 56) AND bcv.dtVenda <= DATE('{date}')
                            THEN bcv.order_id ELSE NULL END), 0), 2) AS vlTicketMedioD56,

    ROUND(SUM(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 365) AND bcv.dtVenda <= DATE('{date}')
                   THEN bcv.price ELSE 0 END) / 
          NULLIF(COUNT(CASE WHEN bcv.dtVenda >= DATE_SUB(DATE('{date}'), 365) AND bcv.dtVenda <= DATE('{date}')
                            THEN bcv.order_id ELSE NULL END), 0), 2) AS vlTicketMedioD365

FROM base_sellers bs
LEFT JOIN base_com_venda_anterior bcv ON bs.seller_id = bcv.seller_id
GROUP BY bs.seller_id

)

SELECT 
    '{date}' AS dtRef,
    *

FROM tb_final