-- Databricks notebook source

WITH tb_pedidos AS (
  SELECT *
  FROM bronze.olist.orders
  WHERE order_purchase_timestamp < '2018-07-01'
),

tb_itens_pedidos_periodo AS (
  SELECT
    p.order_id,
    p.customer_id,
    p.order_purchase_timestamp,
    DATE(p.order_purchase_timestamp) AS order_date,
    DATE_TRUNC('month', p.order_purchase_timestamp) AS order_month,

    i.seller_id,

    SUM(i.price) AS receita_produto,
    SUM(i.freight_value) AS receita_frete,
    SUM(i.price + i.freight_value) AS receita_total

  FROM tb_pedidos p

  INNER JOIN bronze.olist.order_items i
    ON p.order_id = i.order_id

  GROUP BY
    p.order_id,
    p.customer_id,
    p.order_purchase_timestamp,
    DATE(p.order_purchase_timestamp),
    DATE_TRUNC('month', p.order_purchase_timestamp),
    i.seller_id
),

tb_geo AS (
  SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude
  FROM bronze.olist.geolocation
  GROUP BY geolocation_zip_code_prefix
),

tb_base_seller_orders AS (
  SELECT
    s.seller_id,

    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state,

    i.order_id,
    i.customer_id,
    i.order_purchase_timestamp,
    i.order_date,
    i.order_month,

    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,

    COALESCE(i.receita_produto, 0) AS receita_produto,
    COALESCE(i.receita_frete, 0) AS receita_frete,
    COALESCE(i.receita_total, 0) AS receita_total,

    geo_seller.latitude AS seller_latitude,
    geo_seller.longitude AS seller_longitude,

    geo_customer.latitude AS customer_latitude,
    geo_customer.longitude AS customer_longitude,

    CASE
      WHEN s.seller_state IN ('AM','RR','AP','PA','TO','RO','AC') THEN 'Norte'
      WHEN s.seller_state IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA') THEN 'Nordeste'
      WHEN s.seller_state IN ('MT','MS','GO','DF') THEN 'Centro-Oeste'
      WHEN s.seller_state IN ('SP','RJ','MG','ES') THEN 'Sudeste'
      WHEN s.seller_state IN ('PR','SC','RS') THEN 'Sul'
      ELSE 'Não identificado'
    END AS regiao_seller,

    CASE
      WHEN UPPER(s.seller_city) IN (
        'RIO BRANCO', 'MACEIO', 'MACAPA', 'MANAUS', 'SALVADOR',
        'FORTALEZA', 'BRASILIA', 'VITORIA', 'GOIANIA', 'SAO LUIS',
        'CUIABA', 'CAMPO GRANDE', 'BELO HORIZONTE', 'BELEM',
        'JOAO PESSOA', 'CURITIBA', 'RECIFE', 'TERESINA',
        'RIO DE JANEIRO', 'NATAL', 'PORTO ALEGRE', 'PORTO VELHO',
        'BOA VISTA', 'FLORIANOPOLIS', 'SAO PAULO', 'ARACAJU', 'PALMAS'
      ) THEN 1
      ELSE 0
    END AS flag_seller_capital,

    CASE
      WHEN i.order_id IS NOT NULL
      AND geo_seller.latitude IS NOT NULL
      AND geo_seller.longitude IS NOT NULL
      AND geo_customer.latitude IS NOT NULL
      AND geo_customer.longitude IS NOT NULL
      THEN ROUND(6371 * 2 * ASIN(
        SQRT(
          POWER(SIN(RADIANS(geo_customer.latitude - geo_seller.latitude) / 2), 2)
          +
          COS(RADIANS(geo_seller.latitude))
          * COS(RADIANS(geo_customer.latitude))
          * POWER(SIN(RADIANS(geo_customer.longitude - geo_seller.longitude) / 2), 2)
        )
      ))
      ELSE NULL
    END AS distancia_km

  FROM bronze.olist.sellers s

  LEFT JOIN tb_itens_pedidos_periodo i
    ON s.seller_id = i.seller_id

  LEFT JOIN bronze.olist.customers c
    ON i.customer_id = c.customer_id

  LEFT JOIN tb_geo geo_seller
    ON s.seller_zip_code_prefix = geo_seller.geolocation_zip_code_prefix

  LEFT JOIN tb_geo geo_customer
    ON c.customer_zip_code_prefix = geo_customer.geolocation_zip_code_prefix
),

tb_seller AS (
  SELECT
    seller_id,

    MAX(seller_city) AS seller_city,
    MAX(seller_state) AS seller_state,
    MAX(regiao_seller) AS regiao_seller,
    MAX(flag_seller_capital) AS flag_seller_capital,

    COUNT(DISTINCT order_id) AS qtd_pedidos_seller,

    SUM(receita_total) AS receita_total_seller,

    COUNT(DISTINCT customer_state) AS qtd_ufs_atendidas,

    COUNT(DISTINCT CASE 
      WHEN customer_state IS NOT NULL 
      THEN CONCAT(customer_state, '|', customer_city) 
    END) AS qtd_cidades_atendidas,

    COUNT(DISTINCT CASE 
      WHEN customer_state = seller_state 
      THEN order_id 
    END) AS qtd_pedidos_proprio_estado,

    COUNT(DISTINCT CASE 
      WHEN customer_state = seller_state
       AND customer_city = seller_city
      THEN order_id 
    END) AS qtd_pedidos_propria_cidade,

    SUM(CASE 
      WHEN customer_state = seller_state 
      THEN receita_total 
      ELSE 0 
    END) AS receita_proprio_estado,

    SUM(CASE 
      WHEN customer_state = seller_state
       AND customer_city = seller_city
      THEN receita_total 
      ELSE 0 
    END) AS receita_propria_cidade,

    AVG(distancia_km) AS media_distancia_km,
    PERCENTILE_APPROX(distancia_km, 0.5) AS mediana_distancia_km,
    MAX(distancia_km) AS max_distancia_km,
    MIN(distancia_km) AS min_distancia_km,

    COUNT(DISTINCT CASE 
      WHEN distancia_km <= 100 
      THEN order_id 
    END) AS qtd_pedidos_curta_distancia,

    COUNT(DISTINCT CASE 
      WHEN distancia_km > 100 
       AND distancia_km <= 500
      THEN order_id 
    END) AS qtd_pedidos_media_distancia,

    COUNT(DISTINCT CASE 
      WHEN distancia_km > 500
      THEN order_id 
    END) AS qtd_pedidos_longa_distancia

  FROM tb_base_seller_orders
  GROUP BY seller_id
),

tb_volume_estado_seller AS (
  SELECT
    seller_state,
    COUNT(DISTINCT order_id) AS volume_total_pedidos_estado_seller
  FROM tb_base_seller_orders
  GROUP BY seller_state
),

tb_volume_cidade_seller AS (
  SELECT
    seller_state,
    seller_city,
    COUNT(DISTINCT order_id) AS volume_total_pedidos_cidade_seller
  FROM tb_base_seller_orders
  GROUP BY seller_state, seller_city
),

tb_rank_estado AS (
  SELECT
    seller_id,
    RANK() OVER (
      PARTITION BY seller_state
      ORDER BY qtd_pedidos_seller DESC
    ) AS rank_seller_pedidos_estado
  FROM tb_seller
),

tb_rank_cidade AS (
  SELECT
    seller_id,
    RANK() OVER (
      PARTITION BY seller_state, seller_city
      ORDER BY qtd_pedidos_seller DESC
    ) AS rank_seller_pedidos_cidade
  FROM tb_seller
),

tb_estado_destino AS (
  SELECT
    seller_id,
    customer_state,
    COUNT(DISTINCT order_id) AS qtd_pedidos_estado_destino
  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY seller_id, customer_state
),

tb_cidade_destino AS (
  SELECT
    seller_id,
    customer_state,
    customer_city,
    COUNT(DISTINCT order_id) AS qtd_pedidos_cidade_destino
  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY seller_id, customer_state, customer_city
),

tb_principal_estado AS (
  SELECT
    seller_id,
    customer_state AS principal_estado_pedidos_seller,
    qtd_pedidos_estado_destino AS qtd_pedidos_principal_estado
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY seller_id
        ORDER BY qtd_pedidos_estado_destino DESC, customer_state
      ) AS rn
    FROM tb_estado_destino
  )
  WHERE rn = 1
),

tb_principal_cidade AS (
  SELECT
    seller_id,
    customer_state AS uf_principal_cidade_pedidos_seller,
    customer_city AS principal_cidade_pedidos_seller,
    qtd_pedidos_cidade_destino AS qtd_pedidos_principal_cidade
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY seller_id
        ORDER BY qtd_pedidos_cidade_destino DESC, customer_state, customer_city
      ) AS rn
    FROM tb_cidade_destino
  )
  WHERE rn = 1
),

tb_mercado_estado_destino AS (
  SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS qtd_pedidos_total_estado_destino,
    SUM(receita_total) AS receita_total_estado_destino
  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY customer_state
),

tb_mercado_cidade_destino AS (
  SELECT
    customer_state,
    customer_city,
    COUNT(DISTINCT order_id) AS qtd_pedidos_total_cidade_destino,
    SUM(receita_total) AS receita_total_cidade_destino
  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY customer_state, customer_city
),

tb_media_estado_seller AS (
  SELECT
    seller_state,
    AVG(qtd_pedidos_seller) AS media_pedidos_sellers_mesmo_estado
  FROM tb_seller
  GROUP BY seller_state
),

tb_media_cidade_seller AS (
  SELECT
    seller_state,
    seller_city,
    AVG(qtd_pedidos_seller) AS media_pedidos_sellers_mesma_cidade
  FROM tb_seller
  GROUP BY seller_state, seller_city
),

tb_sellers AS (
  SELECT DISTINCT
    seller_id
  FROM tb_base_seller_orders
),

tb_estados_mercado AS (
  SELECT DISTINCT
    customer_state
  FROM tb_base_seller_orders
  WHERE customer_state IS NOT NULL
),

tb_seller_estado_completo AS (
  SELECT
    s.seller_id,
    e.customer_state
  FROM tb_sellers s
  CROSS JOIN tb_estados_mercado e --utilizando cross join para pegar a combinacao do seller com todos os estados
),

tb_pedidos_seller_estado AS (
  SELECT
    seller_id,
    customer_state,
    COUNT(DISTINCT order_id) AS qtd_pedidos_seller_estado
  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY seller_id, customer_state
),

tb_share_seller_estado AS (
  SELECT
    c.seller_id,
    c.customer_state,

    COALESCE(p.qtd_pedidos_seller_estado, 0) AS qtd_pedidos_seller_estado,

    CASE
      WHEN SUM(COALESCE(p.qtd_pedidos_seller_estado, 0)) OVER (PARTITION BY c.seller_id) = 0
      THEN 0
      ELSE COALESCE(p.qtd_pedidos_seller_estado, 0) * 1.0
        / SUM(COALESCE(p.qtd_pedidos_seller_estado, 0)) OVER (PARTITION BY c.seller_id)
    END AS peso_estado_nos_pedidos_seller

  FROM tb_seller_estado_completo c
  LEFT JOIN tb_pedidos_seller_estado p
    ON c.seller_id = p.seller_id
   AND c.customer_state = p.customer_state
),

tb_share_mercado_estado AS (
  SELECT
    customer_state,

    COUNT(DISTINCT order_id) AS qtd_pedidos_mercado_estado,

    COUNT(DISTINCT order_id) * 1.0
      / SUM(COUNT(DISTINCT order_id)) OVER () AS peso_estado_no_mercado

  FROM tb_base_seller_orders
  WHERE order_id IS NOT NULL
  GROUP BY customer_state
),

tb_gap_estado AS (
  SELECT
    s.seller_id,
    s.customer_state,
    s.peso_estado_nos_pedidos_seller,
    m.peso_estado_no_mercado,

    s.peso_estado_nos_pedidos_seller - m.peso_estado_no_mercado AS gap_estado

  FROM tb_share_seller_estado s
  LEFT JOIN tb_share_mercado_estado m
    ON s.customer_state = m.customer_state
),

tb_gap_estado_agg AS (
  SELECT
    seller_id,

    SUM(CASE 
      WHEN gap_estado > 0 
      THEN gap_estado 
      ELSE 0 
    END) AS soma_gap_estado_positivo,

    SUM(ABS(gap_estado)) AS soma_abs_gap_estado,

    1 - (SUM(ABS(gap_estado)) / 2) AS score_cobertura_estado

  FROM tb_gap_estado
  GROUP BY seller_id
)

SELECT
  s.seller_id,

  s.seller_city,
  s.seller_state,

  s.regiao_seller,
  s.flag_seller_capital,

  COALESCE(ve.volume_total_pedidos_estado_seller, 0) AS volume_total_pedidos_estado_seller,
  COALESCE(vc.volume_total_pedidos_cidade_seller, 0) AS volume_total_pedidos_cidade_seller,

  COALESCE(s.qtd_pedidos_seller, 0) AS qtd_pedidos_seller,
  COALESCE(s.receita_total_seller, 0) AS receita_total_seller,

  COALESCE(s.qtd_ufs_atendidas, 0) AS qtd_ufs_atendidas,
  COALESCE(s.qtd_cidades_atendidas, 0) AS qtd_cidades_atendidas,

  COALESCE(s.qtd_pedidos_proprio_estado, 0) AS qtd_pedidos_proprio_estado,
  COALESCE(s.qtd_pedidos_propria_cidade, 0) AS qtd_pedidos_propria_cidade,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE s.qtd_pedidos_proprio_estado * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_proprio_estado,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE s.qtd_pedidos_propria_cidade * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_propria_cidade,

  CASE 
    WHEN me.qtd_pedidos_total_estado_destino IS NULL 
      OR me.qtd_pedidos_total_estado_destino = 0 
    THEN 0
    ELSE s.qtd_pedidos_proprio_estado * 1.0 / me.qtd_pedidos_total_estado_destino
  END AS participacao_pedidos_seller_proprio_estado,

  CASE 
    WHEN mc.qtd_pedidos_total_cidade_destino IS NULL 
      OR mc.qtd_pedidos_total_cidade_destino = 0 
    THEN 0
    ELSE s.qtd_pedidos_propria_cidade * 1.0 / mc.qtd_pedidos_total_cidade_destino
  END AS participacao_pedidos_seller_propria_cidade,

  re.rank_seller_pedidos_estado,
  rc.rank_seller_pedidos_cidade,

  COALESCE(s.receita_proprio_estado, 0) AS receita_proprio_estado,
  COALESCE(s.receita_propria_cidade, 0) AS receita_propria_cidade,

  CASE 
    WHEN me.receita_total_estado_destino IS NULL 
      OR me.receita_total_estado_destino = 0 
    THEN 0
    ELSE s.receita_proprio_estado / me.receita_total_estado_destino
  END AS participacao_receita_proprio_estado,

  CASE 
    WHEN mc.receita_total_cidade_destino IS NULL 
      OR mc.receita_total_cidade_destino = 0 
    THEN 0
    ELSE s.receita_propria_cidade / mc.receita_total_cidade_destino
  END AS participacao_receita_propria_cidade,

  pe.principal_estado_pedidos_seller AS estado_maior_qtd_pedidos_seller,
  pc.principal_cidade_pedidos_seller AS cidade_maior_qtd_pedidos_seller,

  pc.principal_cidade_pedidos_seller,
  pe.principal_estado_pedidos_seller,

  COALESCE(pe.qtd_pedidos_principal_estado, 0) AS qtd_pedidos_principal_estado,
  COALESCE(pc.qtd_pedidos_principal_cidade, 0) AS qtd_pedidos_principal_cidade,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE pe.qtd_pedidos_principal_estado * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_principal_estado_destino,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE pc.qtd_pedidos_principal_cidade * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_principal_cidade_destino,

  s.media_distancia_km,
  s.mediana_distancia_km,
  s.max_distancia_km,
  s.min_distancia_km,

  COALESCE(s.qtd_pedidos_curta_distancia, 0) AS qtd_pedidos_curta_distancia,
  COALESCE(s.qtd_pedidos_media_distancia, 0) AS qtd_pedidos_media_distancia,
  COALESCE(s.qtd_pedidos_longa_distancia, 0) AS qtd_pedidos_longa_distancia,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE s.qtd_pedidos_curta_distancia * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_curta_distancia,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE s.qtd_pedidos_media_distancia * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_media_distancia,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 0
    ELSE s.qtd_pedidos_longa_distancia * 1.0 / s.qtd_pedidos_seller
  END AS pct_pedidos_longa_distancia,

  me_seller.media_pedidos_sellers_mesmo_estado,
  mc_seller.media_pedidos_sellers_mesma_cidade,

  s.qtd_pedidos_seller - me_seller.media_pedidos_sellers_mesmo_estado AS dif_pedidos_vs_media_estado,
  s.qtd_pedidos_seller - mc_seller.media_pedidos_sellers_mesma_cidade AS dif_pedidos_vs_media_cidade,

  CASE 
    WHEN me_seller.media_pedidos_sellers_mesmo_estado = 0 THEN NULL
    ELSE s.qtd_pedidos_seller / me_seller.media_pedidos_sellers_mesmo_estado
  END AS razao_pedidos_vs_media_estado,

  CASE 
    WHEN mc_seller.media_pedidos_sellers_mesma_cidade = 0 THEN NULL
    ELSE s.qtd_pedidos_seller / mc_seller.media_pedidos_sellers_mesma_cidade
  END AS razao_pedidos_vs_media_cidade,

  COALESCE(gap.soma_gap_estado_positivo, 0) AS soma_gap_estado_positivo,
  COALESCE(gap.soma_abs_gap_estado, 0) AS soma_abs_gap_estado,
  COALESCE(gap.score_cobertura_estado, 0) AS score_cobertura_estado,

  CASE 
    WHEN s.qtd_pedidos_seller = 0 THEN 1
    ELSE 0
  END AS flag_seller_sem_pedido

FROM tb_seller s

LEFT JOIN tb_volume_estado_seller ve
  ON s.seller_state = ve.seller_state

LEFT JOIN tb_volume_cidade_seller vc
  ON s.seller_state = vc.seller_state
 AND s.seller_city = vc.seller_city

LEFT JOIN tb_rank_estado re
  ON s.seller_id = re.seller_id

LEFT JOIN tb_rank_cidade rc
  ON s.seller_id = rc.seller_id

LEFT JOIN tb_principal_estado pe
  ON s.seller_id = pe.seller_id

LEFT JOIN tb_principal_cidade pc
  ON s.seller_id = pc.seller_id

LEFT JOIN tb_mercado_estado_destino me
  ON s.seller_state = me.customer_state

LEFT JOIN tb_mercado_cidade_destino mc
  ON s.seller_state = mc.customer_state
 AND s.seller_city = mc.customer_city

LEFT JOIN tb_media_estado_seller me_seller
  ON s.seller_state = me_seller.seller_state

LEFT JOIN tb_media_cidade_seller mc_seller
  ON s.seller_state = mc_seller.seller_state
 AND s.seller_city = mc_seller.seller_city

LEFT JOIN tb_gap_estado_agg gap
  ON s.seller_id = gap.seller_id;

