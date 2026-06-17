WITH tb_pedidos AS (
    SELECT *
    FROM workspace.olist.orders
    WHERE order_purchase_timestamp < '{date}'
),

tb_reputation AS (

    SELECT
        toi.seller_id AS idSeller,
    -- ===========================================
    -- Quantidade de avaliações por seller 28,56,365 dias e lifetime
    -- ===========================================
        COUNT(DISTINCT CASE 
            WHEN DATE(tor.review_creation_date) BETWEEN DATE_SUB('{date}', 28) AND '{date}'
            THEN tp.order_id 
        END) AS reviews28d,

        COUNT(DISTINCT CASE 
            WHEN DATE(tor.review_creation_date) BETWEEN DATE_SUB('{date}', 56) AND '{date}'
            THEN tp.order_id 
        END) AS reviews56d,

        COUNT(DISTINCT CASE 
            WHEN DATE(tor.review_creation_date) BETWEEN DATE_SUB('{date}', 365) AND '{date}'
            THEN tp.order_id 
        END) AS reviews365d,

        COUNT(DISTINCT tp.order_id) AS reviewsLifetime,
    -- ===========================================
    -- Percentual de avaliações por seller 28,56,365 dias e lifetime
    -- ===========================================   
        ROUND(
            COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 28)
                    AND tor.order_id IS NOT NULL
                THEN tp.order_id
            END) * 100.0
            /
            NULLIF(COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 28)
                THEN tp.order_id
            END), 0)
        , 2) AS percentual28d,

        ROUND(
            COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 56)
                    AND tor.order_id IS NOT NULL
                THEN tp.order_id
            END) * 100.0
            /
            NULLIF(COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 56)
                THEN tp.order_id
            END), 0)
        , 2) AS percentual56d,

        ROUND(
            COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 365)
                    AND tor.order_id IS NOT NULL
                THEN tp.order_id
            END) * 100.0
            /
            NULLIF(COUNT(DISTINCT CASE
                WHEN CAST(tp.order_purchase_timestamp AS DATE) >= date_sub('{date}', 365)
                THEN tp.order_id
            END), 0)
        , 2) AS percentual365d,

        ROUND(
            COUNT(DISTINCT CASE
                WHEN tor.order_id IS NOT NULL
                THEN tp.order_id
            END) * 100.0
            /
            NULLIF(COUNT(DISTINCT tp.order_id), 0)
        , 2) AS percentualLifetime,
    -- ===========================================
    -- Média das avaliações por seller 28,56,365 dias e lifetime
    -- ===========================================  
        ROUND(AVG(tor.review_score), 2) AS mediaAvaliacoesLifetime,

        ROUND(AVG(CASE
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28
            THEN tor.review_score
        END), 2) AS mediaAvaliacoesD28,

        ROUND(AVG(CASE
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56
            THEN tor.review_score
        END), 2) AS mediaAvaliacoesD56,

        ROUND(AVG(CASE
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365
            THEN tor.review_score
        END), 2) AS mediaAvaliacoesD365,
    -- ===========================================
    -- Desvio Padrão das avaliações por seller 28,56,365 dias e lifetime
    -- ===========================================  
        ROUND(STDDEV(tor.review_score), 2) AS desvpadAvaliacoesLifetime,

        ROUND(STDDEV(CASE 
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28
            THEN tor.review_score
        END), 2) AS desvpadAvaliacoesD28,

        ROUND(STDDEV(CASE
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56
            THEN tor.review_score
        END), 2) AS desvpadAvaliacoesD56,

        ROUND(STDDEV(CASE
            WHEN DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365
            THEN tor.review_score
        END), 2) AS desvpadAvaliacoesD365,
    -- ===========================================
    -- Percentual de avaliações recebidas pelo vendedor com nota 1 por 28,56,365 dias e lifetime
    -- ===========================================  
        ROUND(AVG(CASE WHEN tor.review_score = 1 THEN 1 ELSE 0 END),2) as pctNota1,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) AND (tor.review_score = 1) THEN 1 ELSE 0 END),2) AS pctNota1D28,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) AND  (tor.review_score = 1) THEN 1 ELSE 0 END),2) AS pctNota1D56,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) AND (tor.review_score = 1) THEN 1 ELSE 0 END),2) AS pctNota1D365,
    -- ===========================================
    -- Percentual de avaliações recebidas pelo vendedor com nota 2 por 28,56,365 dias e lifetime
    -- =========================================== 
        ROUND(AVG(CASE WHEN tor.review_score = 2 THEN 1 ELSE 0 END),2) AS pctNota2,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) AND (tor.review_score = 2) THEN 1 ELSE 0 END),2) AS pctNota2D28,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) AND  (tor.review_score = 2) THEN 1 ELSE 0 END),2) AS pctNota2D56,

        ROUND(AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) AND (tor.review_score = 2) THEN 1 ELSE 0 END),2) AS pctNota2D365,
    -- ===========================================
    -- Percentual de avaliações recebidas pelo vendedor com nota 3 por 28,56,365 dias e lifetime
    -- =========================================== 
        AVG(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) AND tor.review_score = 3
                THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) THEN 0 END) AS percNota3D28,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) AND tor.review_score = 3 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) THEN 0 END) AS perc_nota_3_d56,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) AND tor.review_score = 3 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) THEN 0 END) AS percNota3D365,

        AVG(CASE WHEN tor.review_score = 3 THEN 1 ELSE 0 END) AS percNota3Lifetime,
    -- ===========================================
    -- Percentual de avaliações recebidas pelo vendedor com nota 4 por 28,56,365 dias e lifetime
    -- =========================================== 
        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) AND tor.review_score = 4 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) THEN 0 END) AS percNota4D28,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) AND tor.review_score = 4 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) THEN 0 END) AS percNota4D56,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) AND tor.review_score = 4 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) THEN 0 END) AS percNota4D365,

        AVG(CASE WHEN tor.review_score = 4 THEN 1 ELSE 0 END) AS percNota4Lifetime,
    -- ===========================================
    -- Percentual de avaliações recebidas pelo vendedor com nota 5 por 28,56,365 dias e lifetime
    -- =========================================== 
        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) AND tor.review_score = 5 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28) THEN 0 END) AS percNota5D28,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) AND tor.review_score = 5 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56) THEN 0 END) AS percNota5D56,

        AVG(CASE WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) AND tor.review_score = 5 THEN 1
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365) THEN 0 END) AS percNota5D365,

        AVG(CASE WHEN tor.review_score = 5 THEN 1 ELSE 0 END) AS percNota5Lifetime,
    -- ===========================================
    -- Percentual de Notas Boas:
    -- avaliações nota 4 ou 5 / quantidade de pedidos recebidos pelo seller por 28,56,365 dias e lifetime
    -- =========================================== 
        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28)
                AND tor.review_score IN (4, 5)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasBoasD28,

        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56)
                AND tor.review_score IN (4, 5)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasBoasD56,

        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365)
                AND tor.review_score IN (4, 5)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasBoasD365,

        SUM(CASE 
                WHEN tor.review_score IN (4, 5)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(COUNT(toi.order_id), 0) AS pctNotasBoasLifetime,
    -- ===========================================
    --  Percentual de Notas Ruins:
    -- avaliações nota 1 ou 2 / quantidade de pedidos recebidos pelo seller por 28,56,365 dias e lifetime
    -- =========================================== 
        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28)
                AND tor.review_score IN (1, 2)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 28)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasRuinsD28,

        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56)
                AND tor.review_score IN (1, 2)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 56)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasRuinsD56,

        SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365)
                AND tor.review_score IN (1, 2)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(SUM(CASE 
                WHEN (DATE_DIFF('{date}', tp.order_purchase_timestamp) <= 365)
                THEN 1 ELSE 0 
            END), 0) AS pctNotasRuinsD365,

        SUM(CASE 
                WHEN tor.review_score IN (1, 2)
                THEN 1 ELSE 0 
            END) * 1.0
        / NULLIF(COUNT(toi.order_id), 0) AS pctNotasRuinsLifetime



    FROM tb_pedidos AS tp LEFT JOIN olist.order_reviews AS tor ON tp.order_id = tor.order_id
                        LEFT JOIN olist.order_items AS toi ON tp.order_id = toi.order_id

    GROUP BY toi.seller_id 

)

SELECT '{date}' AS dtRef,
        *
FROM tb_reputation