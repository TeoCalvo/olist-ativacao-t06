WITH tb_pedidos AS (

    SELECT *
    FROM workspace.olist.orders
    WHERE order_purchase_timestamp < '2018-07-01'

),

/* =========================================================
   RELACIONA PEDIDOS A SELLERS
   Correção: JOIN com customers para obter customer_unique_id,
   que é o identificador real de pessoa física no dataset Olist.
   O customer_id da tabela orders é por pedido — o mesmo cliente
   pode ter múltiplos customer_id em pedidos distintos.
========================================================= */
tb_orders_sellers AS (

    SELECT DISTINCT
        oi.seller_id,
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        '2018-07-01' AS safra_mes
    FROM tb_pedidos o
    INNER JOIN workspace.olist.order_items oi
        ON o.order_id = oi.order_id
    INNER JOIN workspace.olist.customers c
        ON o.customer_id = c.customer_id

),

/* =========================================================
   SELLERS x SAFRAS
========================================================= */
tb_seller_safra AS (

    SELECT DISTINCT
        seller_id,
        safra_mes
    FROM tb_orders_sellers

),

/* =========================================================
   PERÍODOS ANALÍTICOS
   Adicionado prev_dt_fim para definir a janela anterior
   equivalente de cada período, usada no cálculo de churn.
   Exemplo para 28d: janela anterior = [safra-56d, safra-28d)
========================================================= */
tb_periodos AS (

    SELECT
        seller_id,
        safra_mes,
        '28d'                          AS periodo,
        safra_mes                      AS dt_inicio,
        safra_mes - INTERVAL 28 DAYS   AS dt_fim,
        safra_mes - INTERVAL 56 DAYS   AS prev_dt_fim
    FROM tb_seller_safra

    UNION ALL

    SELECT
        seller_id,
        safra_mes,
        '56d',
        safra_mes                      AS dt_inicio,
        safra_mes - INTERVAL 56 DAYS   AS dt_fim,
        safra_mes - INTERVAL 112 DAYS  AS prev_dt_fim
    FROM tb_seller_safra

    UNION ALL

    SELECT
        seller_id,
        safra_mes,
        '365d',
        safra_mes                      AS dt_inicio,
        safra_mes - INTERVAL 365 DAYS  AS dt_fim,
        safra_mes - INTERVAL 730 DAYS  AS prev_dt_fim
    FROM tb_seller_safra

    UNION ALL

    SELECT
        seller_id,
        safra_mes,
        'full',
        safra_mes                      AS dt_inicio,
        DATE('1900-01-01')             AS dt_fim,
        DATE('1900-01-01')             AS prev_dt_fim
    FROM tb_seller_safra

),

/* =========================================================
   BASE POR PERÍODO
========================================================= */
tb_base_periodo AS (

    SELECT
        p.periodo,
        p.seller_id,
        p.safra_mes,
        p.dt_inicio,
        p.dt_fim,
        o.order_id,
        o.customer_unique_id,
        o.order_purchase_timestamp

    FROM tb_periodos p

    INNER JOIN tb_orders_sellers o
        ON p.seller_id = o.seller_id
       AND o.order_purchase_timestamp < p.dt_inicio
       AND o.order_purchase_timestamp >= p.dt_fim

),

/* =========================================================
   PEDIDOS POR CLIENTE
========================================================= */
tb_cliente_pedidos AS (

    SELECT
        periodo,
        seller_id,
        safra_mes,
        customer_unique_id,
        COUNT(DISTINCT order_id) AS qtd_pedidos_cliente

    FROM tb_base_periodo

    GROUP BY
        periodo,
        seller_id,
        safra_mes,
        customer_unique_id

),

/* =========================================================
   TOTAIS (para cálculo do IHH)
========================================================= */
tb_totais_grupo AS (

    SELECT
        periodo,
        seller_id,
        safra_mes,
        SUM(qtd_pedidos_cliente) AS total_pedidos_grupo

    FROM tb_cliente_pedidos

    GROUP BY
        periodo,
        seller_id,
        safra_mes

),

/* =========================================================
   PRIMEIRA COMPRA HISTÓRICA
========================================================= */
tb_primeira_compra_historica AS (

    SELECT
        seller_id,
        customer_unique_id,
        MIN(order_purchase_timestamp) AS primeira_compra_historica

    FROM tb_orders_sellers

    GROUP BY
        seller_id,
        customer_unique_id

),

/* =========================================================
   INTERVALO ENTRE COMPRAS (para tempo médio real)
========================================================= */
tb_intervalo_compras AS (

    SELECT
        seller_id,
        customer_unique_id,
        order_purchase_timestamp,
        LAG(order_purchase_timestamp)
        OVER (
            PARTITION BY seller_id, customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS compra_anterior

    FROM tb_orders_sellers

),

/* =========================================================
   TEMPO MÉDIO ENTRE RECOMPRAS
   Calcula a média real de dias entre compras consecutivas
   do mesmo cliente para o mesmo seller, dentro de cada
   janela temporal.
========================================================= */
tb_tempo_medio AS (

    SELECT
        p.periodo,
        p.seller_id,
        p.safra_mes,
        AVG(
            DATEDIFF(
                i.order_purchase_timestamp,
                i.compra_anterior
            )
        ) AS tempo_medio_recompra_dias

    FROM tb_periodos p

    INNER JOIN tb_intervalo_compras i
        ON p.seller_id = i.seller_id
       AND i.order_purchase_timestamp < p.dt_inicio
       AND i.order_purchase_timestamp >= p.dt_fim
       AND i.compra_anterior IS NOT NULL

    GROUP BY
        p.periodo,
        p.seller_id,
        p.safra_mes

),

/* =========================================================
   CLIENTES ATIVOS NA JANELA ANTERIOR EQUIVALENTE
   Correção: usa a janela imediatamente anterior de mesmo
   tamanho (prev_dt_fim → dt_fim), em vez de contar todos
   os clientes históricos antes do mês anterior — o que
   gerava o mesmo valor de clientes_ativos_anteriores para
   todos os períodos de um mesmo seller.
   Período 'full' excluído: não possui janela anterior
   equivalente definível.
========================================================= */
tb_clientes_anteriores AS (

    SELECT
        p.periodo,
        p.seller_id,
        p.safra_mes,
        COUNT(DISTINCT o.customer_unique_id) AS clientes_ativos_anteriores

    FROM tb_periodos p

    INNER JOIN tb_orders_sellers o
        ON p.seller_id = o.seller_id
       AND o.order_purchase_timestamp < p.dt_fim
       AND o.order_purchase_timestamp >= p.prev_dt_fim

    WHERE p.periodo != 'full'

    GROUP BY
        p.periodo,
        p.seller_id,
        p.safra_mes

),

/* =========================================================
   CLIENTES CORRENTES (ativos na janela atual)
========================================================= */
tb_clientes_correntes AS (

    SELECT
        periodo,
        seller_id,
        safra_mes,
        COUNT(DISTINCT customer_unique_id) AS clientes_correntes

    FROM tb_base_periodo

    GROUP BY
        periodo,
        seller_id,
        safra_mes

),

/* =========================================================
   CLIENTES PERDIDOS (churn absoluto)
========================================================= */
tb_clientes_perdidos AS (

    SELECT
        a.periodo,
        a.seller_id,
        a.safra_mes,
        GREATEST(
            a.clientes_ativos_anteriores
            - COALESCE(c.clientes_correntes, 0),
            0
        ) AS clientes_perdidos,
        a.clientes_ativos_anteriores

    FROM tb_clientes_anteriores a

    LEFT JOIN tb_clientes_correntes c
        ON a.periodo = c.periodo
       AND a.seller_id = c.seller_id
       AND a.safra_mes = c.safra_mes

),

/* =========================================================
   ÚLTIMO CLIENTE NOVO
========================================================= */
tb_ultimo_cliente_novo AS (

    SELECT
        p.periodo,
        p.seller_id,
        p.safra_mes,
        MAX(h.primeira_compra_historica) AS ultima_data_novo_cliente

    FROM tb_periodos p

    INNER JOIN tb_primeira_compra_historica h
        ON p.seller_id = h.seller_id
       AND h.primeira_compra_historica < p.dt_inicio
       AND h.primeira_compra_historica >= p.dt_fim

    GROUP BY
        p.periodo,
        p.seller_id,
        p.safra_mes

),

/* =========================================================
   MÉTRICAS CONSOLIDADAS
========================================================= */
tb_metricas AS (

    SELECT
        c.periodo,
        c.seller_id,
        c.safra_mes,

        COUNT(DISTINCT c.customer_unique_id)
            AS qtd_clientes_distintos,

        SUM(c.qtd_pedidos_cliente)
            AS total_pedidos,

        COALESCE(
            CAST(
                COUNT(
                    DISTINCT CASE
                        WHEN c.qtd_pedidos_cliente >= 2
                        THEN c.customer_unique_id
                    END
                ) AS DOUBLE
            )
            /
            NULLIF(
                COUNT(DISTINCT c.customer_unique_id),
                0
            ),
            0.0
        ) AS taxa_recompra_periodo,

        COALESCE(
            CAST(
                SUM(c.qtd_pedidos_cliente) AS DOUBLE
            )
            /
            NULLIF(
                COUNT(DISTINCT c.customer_unique_id),
                0
            ),
            0.0
        ) AS avg_pedidos_por_cliente,

        COALESCE(
            SUM(
                POWER(
                    CAST(c.qtd_pedidos_cliente AS DOUBLE)
                    /
                    NULLIF(t.total_pedidos_grupo, 0),
                    2
                )
            ),
            0.0
        ) AS concentracao_ihh

    FROM tb_cliente_pedidos c

    INNER JOIN tb_totais_grupo t
        ON c.periodo = t.periodo
       AND c.seller_id = t.seller_id
       AND c.safra_mes = t.safra_mes

    GROUP BY
        c.periodo,
        c.seller_id,
        c.safra_mes

),

/* =========================================================
   RESULTADO FINAL — PIVOT por período
========================================================= */
tb_final AS (

    SELECT
        m.seller_id AS idSeller,

        /* ========================= 28D ========================= */

        COALESCE(MAX(CASE WHEN m.periodo = '28d'
            THEN m.qtd_clientes_distintos END), 0)
            AS vlQtdClientesDistintos28d,

        COALESCE(MAX(CASE WHEN m.periodo = '28d'
            THEN ROUND(m.taxa_recompra_periodo, 4) END), 0.0)
            AS pctTaxaRecompraPeriodo28d,

        COALESCE(MAX(CASE WHEN m.periodo = '28d'
            THEN ROUND(m.avg_pedidos_por_cliente, 4) END), 0.0)
            AS vlAvgPedidosPorCliente28d,

        COALESCE(MAX(CASE WHEN m.periodo = '28d'
            THEN ROUND(m.concentracao_ihh, 6) END), 0.0)
            AS pctConcentracaoIhh28d,

        COALESCE(MAX(CASE WHEN t.periodo = '28d'
            THEN ROUND(t.tempo_medio_recompra_dias, 2) END), 0.0)
            AS vlTempoMedioRecompra28d,

        COALESCE(MAX(CASE WHEN p.periodo = '28d'
            THEN ROUND(
                CAST(p.clientes_perdidos AS DOUBLE)
                / NULLIF(p.clientes_ativos_anteriores, 0),
                4
            ) END), 0.0)
            AS pctChurnClientes28d,

        COALESCE(MAX(CASE WHEN n.periodo = '28d'
            THEN DATEDIFF(m.safra_mes, n.ultima_data_novo_cliente)
            END), 0)
            AS vlDiasDesdeUltimoClienteNovo28d,

        /* ========================= 56D ========================= */

        COALESCE(MAX(CASE WHEN m.periodo = '56d'
            THEN m.qtd_clientes_distintos END), 0)
            AS vlQtdClientesDistintos56d,

        COALESCE(MAX(CASE WHEN m.periodo = '56d'
            THEN ROUND(m.taxa_recompra_periodo, 4) END), 0.0)
            AS pctTaxaRecompraPeriodo56d,

        COALESCE(MAX(CASE WHEN m.periodo = '56d'
            THEN ROUND(m.avg_pedidos_por_cliente, 4) END), 0.0)
            AS vlAvgPedidosPorCliente56d,

        COALESCE(MAX(CASE WHEN m.periodo = '56d'
            THEN ROUND(m.concentracao_ihh, 6) END), 0.0)
            AS pctConcentracaoIhh56d,

        COALESCE(MAX(CASE WHEN t.periodo = '56d'
            THEN ROUND(t.tempo_medio_recompra_dias, 2) END), 0.0)
            AS vlTempoMedioRecompra56d,

        COALESCE(MAX(CASE WHEN p.periodo = '56d'
            THEN ROUND(
                CAST(p.clientes_perdidos AS DOUBLE)
                / NULLIF(p.clientes_ativos_anteriores, 0),
                4
            ) END), 0.0)
            AS pctChurnClientes56d,

        COALESCE(MAX(CASE WHEN n.periodo = '56d'
            THEN DATEDIFF(m.safra_mes, n.ultima_data_novo_cliente)
            END), 0)
            AS vlDiasDesdeUltimoClienteNovo56d,

        /* ========================= 365D ========================= */

        COALESCE(MAX(CASE WHEN m.periodo = '365d'
            THEN m.qtd_clientes_distintos END), 0)
            AS vlQtdClientesDistintos365d,

        COALESCE(MAX(CASE WHEN m.periodo = '365d'
            THEN ROUND(m.taxa_recompra_periodo, 4) END), 0.0)
            AS pctTaxaRecompraPeriodo365d,

        COALESCE(MAX(CASE WHEN m.periodo = '365d'
            THEN ROUND(m.avg_pedidos_por_cliente, 4) END), 0.0)
            AS vlAvgPedidosPorCliente365d,

        COALESCE(MAX(CASE WHEN m.periodo = '365d'
            THEN ROUND(m.concentracao_ihh, 6) END), 0.0)
            AS pctConcentracaoIhh365d,

        COALESCE(MAX(CASE WHEN t.periodo = '365d'
            THEN ROUND(t.tempo_medio_recompra_dias, 2) END), 0.0)
            AS vlTempoMedioRecompra365d,

        COALESCE(MAX(CASE WHEN p.periodo = '365d'
            THEN ROUND(
                CAST(p.clientes_perdidos AS DOUBLE)
                / NULLIF(p.clientes_ativos_anteriores, 0),
                4
            ) END), 0.0)
            AS pctChurnClientes365d,

        COALESCE(MAX(CASE WHEN n.periodo = '365d'
            THEN DATEDIFF(m.safra_mes, n.ultima_data_novo_cliente)
            END), 0)
            AS vlDiasDesdeUltimoClienteNovo365d,

        /* ========================= FULL ========================= */

        COALESCE(MAX(CASE WHEN m.periodo = 'full'
            THEN m.qtd_clientes_distintos END), 0)
            AS vlQtdClientesDistintosFull,

        COALESCE(MAX(CASE WHEN m.periodo = 'full'
            THEN ROUND(m.taxa_recompra_periodo, 4) END), 0.0)
            AS pctTaxaRecompraPeriodoFull,

        COALESCE(MAX(CASE WHEN m.periodo = 'full'
            THEN ROUND(m.avg_pedidos_por_cliente, 4) END), 0.0)
            AS vlAvgPedidosPorClienteFull,

        COALESCE(MAX(CASE WHEN m.periodo = 'full'
            THEN ROUND(m.concentracao_ihh, 6) END), 0.0)
            AS pctConcentracaoIhhFull,

        COALESCE(MAX(CASE WHEN t.periodo = 'full'
            THEN ROUND(t.tempo_medio_recompra_dias, 2) END), 0.0)
            AS vlTempoMedioRecompraFull,

        COALESCE(MAX(CASE WHEN n.periodo = 'full'
            THEN DATEDIFF(m.safra_mes, n.ultima_data_novo_cliente)
            END), 0)
            AS vlDiasDesdeUltimoClienteNovoFull

    FROM tb_metricas m

    LEFT JOIN tb_tempo_medio t
        ON m.periodo = t.periodo
    AND m.seller_id = t.seller_id
    AND m.safra_mes = t.safra_mes

    LEFT JOIN tb_clientes_perdidos p
        ON m.periodo = p.periodo
    AND m.seller_id = p.seller_id
    AND m.safra_mes = p.safra_mes

    LEFT JOIN tb_ultimo_cliente_novo n
        ON m.periodo = n.periodo
    AND m.seller_id = n.seller_id
    AND m.safra_mes = n.safra_mes

    GROUP BY
        m.seller_id

    ORDER BY
        m.seller_id
)

SELECT '{date}' AS dtRef,
        *
FROM tb_final