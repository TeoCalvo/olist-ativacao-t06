-- ============================================================
-- Seller RFV + Métricas de Engajamento
-- Referência: {date} | Granularidade: 1 linha por seller
-- ============================================================

  WITH params AS (
    -- Define a data de referência utilizada nos cálculos
      SELECT DATE('{date}') AS dt_ref
  ),

  tb_base AS (
      SELECT
          oi.seller_id,
          o.order_id,
          oi.product_id,
          oi.price,
          o.order_status,
          DATE(o.order_purchase_timestamp) AS dtVenda,
          o.order_purchase_timestamp,
          p.dt_ref,
          DATEDIFF(p.dt_ref, o.order_purchase_timestamp) AS dias_ref
      FROM workspace.olist.orders        o
      INNER JOIN workspace.olist.order_items oi ON o.order_id = oi.order_id
      CROSS JOIN params p
      WHERE o.order_purchase_timestamp < p.dt_ref
  ),

  tb_sellers AS (
    -- Lista de sellers com pelo menos uma venda antes da data de referência
      SELECT DISTINCT seller_id FROM tb_base
  ),

-- ============================================================
-- Intervalos entre vendas
-- ============================================================
tb_intervalo_vendas AS (

    -- Obtém a data da venda anterior de cada seller
    WITH tb_lag AS (
        SELECT
            seller_id,
            dtVenda,
            LAG(dtVenda) OVER (PARTITION BY seller_id ORDER BY dtVenda) AS dtVendaAnterior

        FROM (
            SELECT DISTINCT seller_id, dtVenda
            FROM tb_base
        )
    )

    SELECT
        seller_id,

        -- Estatísticas dos dias entre vendas consecutivas
        ROUND(AVG(DATEDIFF(day, dtVendaAnterior, dtVenda)), 2) AS vlDiasEntreVendasMedio,
        MIN(DATEDIFF(day, dtVendaAnterior, dtVenda)) AS vlDiasEntreVendasMin,
        MAX(DATEDIFF(day, dtVendaAnterior, dtVenda)) AS vlDiasEntreVendasMax,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY DATEDIFF(day, dtVendaAnterior, dtVenda)) AS vlDiasEntreVendasP25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY DATEDIFF(day, dtVendaAnterior, dtVenda)) AS vlDiasEntreVendasP50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY DATEDIFF(day, dtVendaAnterior, dtVenda)) AS vlDiasEntreVendasP75
    
    FROM tb_lag

    -- Remove a primeira venda de cada seller pois não existe venda anterior
    WHERE dtVendaAnterior IS NOT NULL
    GROUP BY seller_id
),

  -- ============================================================
  -- Pedidos por período, status, itens, recência
  -- ============================================================
  tb_pedidos AS (
      SELECT
          seller_id,

          COUNT(DISTINCT order_id)
  AS qtdPedidosVida,
          COUNT(DISTINCT CASE WHEN dias_ref <= 28  THEN order_id END) AS qtdPedidosD28,
          COUNT(DISTINCT CASE WHEN dias_ref <= 56  THEN order_id END) AS qtdPedidosD56,
          COUNT(DISTINCT CASE WHEN dias_ref <= 365 THEN order_id END) AS qtdPedidosD365,

          -- delivered
          COUNT(DISTINCT CASE WHEN order_status = 'delivered'
         THEN order_id END) AS qtdPedidosDeliveredVida,
          COUNT(DISTINCT CASE WHEN order_status = 'delivered' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosDeliveredD28,
          COUNT(DISTINCT CASE WHEN order_status = 'delivered' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosDeliveredD56,
          COUNT(DISTINCT CASE WHEN order_status = 'delivered' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosDeliveredD365,

          -- invoiced
          COUNT(DISTINCT CASE WHEN order_status = 'invoiced'
         THEN order_id END) AS qtdPedidosInvoicedVida,
          COUNT(DISTINCT CASE WHEN order_status = 'invoiced' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosInvoicedD28,
          COUNT(DISTINCT CASE WHEN order_status = 'invoiced' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosInvoicedD56,
          COUNT(DISTINCT CASE WHEN order_status = 'invoiced' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosInvoicedD365,

          -- shipped
          COUNT(DISTINCT CASE WHEN order_status = 'shipped'
         THEN order_id END) AS qtdPedidosShippedVida,
          COUNT(DISTINCT CASE WHEN order_status = 'shipped' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosShippedD28,
          COUNT(DISTINCT CASE WHEN order_status = 'shipped' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosShippedD56,
          COUNT(DISTINCT CASE WHEN order_status = 'shipped' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosShippedD365,

          -- processing
          COUNT(DISTINCT CASE WHEN order_status = 'processing'
         THEN order_id END) AS qtdPedidosProcessingVida,
          COUNT(DISTINCT CASE WHEN order_status = 'processing' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosProcessingD28,
          COUNT(DISTINCT CASE WHEN order_status = 'processing' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosProcessingD56,
          COUNT(DISTINCT CASE WHEN order_status = 'processing' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosProcessingD365,

          -- unavailable
          COUNT(DISTINCT CASE WHEN order_status = 'unavailable'
         THEN order_id END) AS qtdPedidosUnavailableVida,
          COUNT(DISTINCT CASE WHEN order_status = 'unavailable' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosUnavailableD28,
          COUNT(DISTINCT CASE WHEN order_status = 'unavailable' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosUnavailableD56,
          COUNT(DISTINCT CASE WHEN order_status = 'unavailable' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosUnavailableD365,

          -- canceled
          COUNT(DISTINCT CASE WHEN order_status = 'canceled'
         THEN order_id END) AS qtdPedidosCanceledVida,
          COUNT(DISTINCT CASE WHEN order_status = 'canceled' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosCanceledD28,
          COUNT(DISTINCT CASE WHEN order_status = 'canceled' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosCanceledD56,
          COUNT(DISTINCT CASE WHEN order_status = 'canceled' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosCanceledD365,

          -- created
          COUNT(DISTINCT CASE WHEN order_status = 'created'
         THEN order_id END) AS qtdPedidosCreatedVida,
          COUNT(DISTINCT CASE WHEN order_status = 'created' AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosCreatedD28,
          COUNT(DISTINCT CASE WHEN order_status = 'created' AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosCreatedD56,
          COUNT(DISTINCT CASE WHEN order_status = 'created' AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosCreatedD365,

          -- approved
          COUNT(DISTINCT CASE WHEN order_status = 'approved'
         THEN order_id END) AS qtdPedidosApprovedVida,
          COUNT(DISTINCT CASE WHEN order_status = 'approved'   AND dias_ref <= 28
  THEN order_id END) AS qtdPedidosApprovedD28,
          COUNT(DISTINCT CASE WHEN order_status = 'approved'   AND dias_ref <= 56
  THEN order_id END) AS qtdPedidosApprovedD56,
          COUNT(DISTINCT CASE WHEN order_status = 'approved'   AND dias_ref <= 365
  THEN order_id END) AS qtdPedidosApprovedD365,

          COUNT(product_id)
  AS qtdItensVendaVida,
          COUNT(CASE WHEN dias_ref <= 28  THEN product_id END) AS qtdItensVendaD28,
          COUNT(CASE WHEN dias_ref <= 56  THEN product_id END) AS qtdItensVendaD56,
          COUNT(CASE WHEN dias_ref <= 365 THEN product_id END) AS qtdItensVendaD365,

          MIN(dias_ref) AS diasDesdeUltimaVenda,
          MAX(dias_ref) AS diasDesdePrimeiraVenda

      FROM tb_base
      GROUP BY seller_id
  ),

  -- ============================================================
  -- Dias com venda e engajamento
  -- ============================================================
  tb_dias_vendas AS (
    SELECT
        seller_id,

        -- Dias distintos com venda por período
        COUNT(DISTINCT dtVenda) AS qtdDiasVendasTotal,
        COUNT(DISTINCT CASE WHEN dias_ref <= 28  THEN dtVenda END) AS qtdDiasVendasD28,
        COUNT(DISTINCT CASE WHEN dias_ref <= 56  THEN dtVenda END) AS qtdDiasVendasD56,
        COUNT(DISTINCT CASE WHEN dias_ref <= 365 THEN dtVenda END) AS qtdDiasVendasD365,

        -- Dias sem venda desde a primeira venda
        MAX(dias_ref) - COUNT(DISTINCT dtVenda) AS qtdDiasSemVendas,

        -- Dias com venda ÷ dias sem venda
        ROUND(COALESCE(TRY_DIVIDE(
            COUNT(DISTINCT dtVenda),
            MAX(dias_ref) - COUNT(DISTINCT dtVenda)
        ), 0), 2) AS txEngajamento

    FROM tb_base
    GROUP BY seller_id
),

  -- ============================================================
  -- Receita e ticket médio
  -- ============================================================
  tb_receita AS (

    -- Consolida a receita por pedido e seller
    WITH tb_pedido_seller AS (
        SELECT
            seller_id,
            order_id,
            dtVenda,
            dt_ref,
            SUM(price) AS receita
        FROM tb_base
        GROUP BY seller_id, order_id, dtVenda, dt_ref
    )

    SELECT
        seller_id,

        -- Receita por período
        SUM(receita) AS vlReceitaVida,
        SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 28)  THEN receita ELSE 0 END) AS vlReceitaD28,
        SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 56)  THEN receita ELSE 0 END) AS vlReceitaD56,
        SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 365) THEN receita ELSE 0 END) AS vlReceitaD365,

        -- Ticket médio por período
        ROUND(TRY_DIVIDE(SUM(receita), COUNT(order_id)), 2) AS vlTicketMedioVida,
        ROUND(TRY_DIVIDE(
            SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 28) THEN receita END),
            COUNT(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 28) THEN order_id END)
        ), 2) AS vlTicketMedioD28,
        ROUND(TRY_DIVIDE(
            SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 56) THEN receita END),
            COUNT(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 56) THEN order_id END)
        ), 2) AS vlTicketMedioD56,
        ROUND(TRY_DIVIDE(
            SUM(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 365) THEN receita END),
            COUNT(CASE WHEN dtVenda >= DATE_SUB(dt_ref, 365) THEN order_id END)
        ), 2) AS vlTicketMedioD365

    FROM tb_pedido_seller
    GROUP BY seller_id
)

-- ============================================================
-- Consolidação das métricas por seller
-- ============================================================
tb_final AS (

    SELECT
        s.seller_id AS idSeller,

        -- Intervalos entre vendas
        iv.* EXCEPT (seller_id),

        -- Pedidos, status e recência
        p.* EXCEPT (seller_id),

        -- Proporção de pedidos por período
        ROUND(TRY_DIVIDE(p.qtdPedidosD28,  p.qtdPedidosVida), 2) AS txPropPedidosD28,
        ROUND(TRY_DIVIDE(p.qtdPedidosD56,  p.qtdPedidosVida), 2) AS txPropPedidosD56,
        ROUND(TRY_DIVIDE(p.qtdPedidosD365, p.qtdPedidosVida), 2) AS txPropPedidosD365,

        -- Dias com venda e ativação
        dv.* EXCEPT (seller_id),
        ROUND(TRY_DIVIDE(dv.qtdDiasVendasTotal, p.diasDesdePrimeiraVenda), 2) AS txAtivacaoPorDiaVida,
        ROUND(TRY_DIVIDE(dv.qtdDiasVendasD28, 28), 2) AS txAtivacaoPorDiaD28,
        ROUND(TRY_DIVIDE(dv.qtdDiasVendasD56, 56), 2) AS txAtivacaoPorDiaD56,
        ROUND(TRY_DIVIDE(dv.qtdDiasVendasD365, 365), 2) AS txAtivacaoPorDiaD365,

        -- Receita e ticket médio
        r.* EXCEPT (seller_id)

    FROM tb_sellers s
    LEFT JOIN tb_intervalo_vendas iv ON s.seller_id = iv.seller_id
    LEFT JOIN tb_pedidos p ON s.seller_id = p.seller_id
    LEFT JOIN tb_dias_vendas dv ON s.seller_id = dv.seller_id
    LEFT JOIN tb_receita r ON s.seller_id = r.seller_id

)

SELECT '{date}' AS dtRef,
       *

FROM tb_final