-- 1 Tabela base de pedidos com filtro de safra embutido
WITH tb_pedidos AS (
  SELECT order_id, order_purchase_timestamp
  FROM workspace.olist.orders
  WHERE order_purchase_timestamp < '{date}'
),

-- 2 Tabela base de itens
tb_itens AS (
  SELECT
    i.seller_id
    , o.order_id
    , o.order_purchase_timestamp
    , i.order_item_id
    , IFNULL(p.product_category_name, 'NA') AS product_category_name
    , i.product_id
    , i.price
    , i.freight_value

    , IFNULL(p.product_description_lenght, 0) AS product_description_length
    , IFNULL(p.product_photos_qty, 0) AS product_photos_qty
    , p.product_weight_g / 1000 AS product_weight_kg
    , p.product_length_cm * p.product_height_cm * p.product_width_cm AS product_cubic_volume_cm3
  FROM tb_pedidos AS o
  INNER JOIN olist.order_items AS i
    ON i.order_id = o.order_id
  LEFT JOIN olist.products AS p
    ON p.product_id = i.product_id
),

-- 3 Listagem de seller_id e product_category_name. Flag 1 caso tenha tido vendas na janela, caso contrário 0.
tb_seller_category_list AS (
    SELECT
        seller_id
        , product_category_name
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN 1 ELSE 0 END) AS hadCatSale14d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN 1 ELSE 0 END) AS hadCatSale28d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN 1 ELSE 0 END) AS hadCatSale56d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN 1 ELSE 0 END) AS hadCatSale365d
        , 1 AS hadCatSaleVida
    FROM tb_itens
    GROUP BY seller_id, product_category_name
),

-- 4 Listagem de seller_id e product_id. Flag 1 caso tenha tido vendas na janela, caso contrário 0.
tb_seller_product_list AS (
    SELECT
        seller_id
        , product_id
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN 1 ELSE 0 END) AS hadProdSale14d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN 1 ELSE 0 END) AS hadProdSale28d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN 1 ELSE 0 END) AS hadProdSale56d
        , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN 1 ELSE 0 END) AS hadProdSale365d
        , 1 AS hadProdSaleVida
    FROM tb_itens
    GROUP BY seller_id, product_id
),

-- 5 Contagem de vendedores distintos por categoria
tb_category_window AS (
  SELECT
    product_category_name
    , SUM(hadCatSale14d) AS ctDistinctCatSellers14d
    , SUM(hadCatSale28d) AS ctDistinctCatSellers28d
    , SUM(hadCatSale56d) AS ctDistinctCatSellers56d
    , SUM(hadCatSale365d) AS ctDistinctCatSellers365d
    , SUM(hadCatSaleVida) AS ctDistinctCatSellersVida
  FROM tb_seller_category_list
  GROUP BY product_category_name
),

-- 6 Contagem de vendedores distintos por produto
tb_product_window AS (
  SELECT
    product_id
    , SUM(hadProdSale14d) AS ctDistinctProdSellers14d
    , SUM(hadProdSale28d) AS ctDistinctProdSellers28d
    , SUM(hadProdSale56d) AS ctDistinctProdSellers56d
    , SUM(hadProdSale365d) AS ctDistinctProdSellers365d
    , SUM(hadProdSaleVida) AS ctDistinctProdSellersVida
  FROM tb_seller_product_list
  GROUP BY product_id
),

-- 7 Contagem de concorrentes de categorias por seller_id (3 + 5)
tb_category_competitity AS (
    SELECT
        t1.seller_id
        , SUM(ctDistinctCatSellers14d - hadCatSale14d) AS vlContagemCategoriaConcorrentesD14
        , SUM(ctDistinctCatSellers28d - hadCatSale28d) AS vlContagemCategoriaConcorrentesD28
        , SUM(ctDistinctCatSellers56d - hadCatSale56d) AS vlContagemCategoriaConcorrentesD56
        , SUM(ctDistinctCatSellers365d - hadCatSale365d) AS vlContagemCategoriaConcorrentesD365
        , SUM(ctDistinctCatSellersVida - hadCatSaleVida) AS vlContagemCategoriaConcorrentesVida
    FROM tb_seller_category_list AS t1
    LEFT JOIN tb_category_window AS t2
        ON t1.product_category_name = t2.product_category_name
    GROUP BY t1.seller_id
),

-- 8 Contagem de concorrentes de produtos por seller_id (4 + 6)
tb_product_competitity AS (
    SELECT
        t1.seller_id
        , SUM(ctDistinctProdSellers14d - hadProdSale14d) AS vlContagemProdutosConcorrentesD14
        , SUM(ctDistinctProdSellers28d - hadProdSale28d) AS vlContagemProdutosConcorrentesD28
        , SUM(ctDistinctProdSellers56d - hadProdSale56d) AS vlContagemProdutosConcorrentesD56
        , SUM(ctDistinctProdSellers365d - hadProdSale365d) AS vlContagemProdutosConcorrentesD365
        , SUM(ctDistinctProdSellersVida - hadProdSaleVida) AS vlContagemProdutosConcorrentesVida
    FROM tb_seller_product_list AS t1
    LEFT JOIN tb_product_window AS t2
        ON t1.product_id = t2.product_id
    GROUP BY t1.seller_id
),

-- 9 Conta quantidade distinta de categorias distintas de seller_id
tb_seller_cat_count AS (
  SELECT
    seller_id,
    SUM(hadCatSale14d) AS vlCategoriasDistintasD14,
    SUM(hadCatSale28d) AS vlCategoriasDistintasD28,
    SUM(hadCatSale56d) AS vlCategoriasDistintasD56,
    SUM(hadCatSale365d) AS vlCategoriasDistintasD365,
    SUM(hadCatSaleVida) AS vlCategoriasDistintasVida
  FROM tb_seller_category_list
  GROUP BY seller_id
),

-- 10 Conta quantidade distinta de produtos distintas de seller_id
tb_seller_prod_count AS (
  SELECT
    seller_id,
    SUM(hadProdSale14d) AS vlProdutosDistintosD14,
    SUM(hadProdSale28d) AS vlProdutosDistintosD28,
    SUM(hadProdSale56d) AS vlProdutosDistintosD56,
    SUM(hadProdSale365d) AS vlProdutosDistintosD365,
    SUM(hadProdSaleVida) AS vlProdutosDistintosVida
  FROM tb_seller_product_list
  GROUP BY seller_id
),

-- 11 Contagem de quantidade de categorias e produtos distintos nas janelas (9 + 10)
tb_seller_cat_prod_count AS (
  SELECT
    COALESCE(t1.seller_id, t2.seller_id) AS seller_id

    , t1.vlCategoriasDistintasD14
    , t1.vlCategoriasDistintasD28
    , t1.vlCategoriasDistintasD56
    , t1.vlCategoriasDistintasD365
    , t1.vlCategoriasDistintasVida

    , t2.vlProdutosDistintosD14
    , t2.vlProdutosDistintosD28
    , t2.vlProdutosDistintosD56
    , t2.vlProdutosDistintosD365
    , t2.vlProdutosDistintosVida

  FROM tb_seller_cat_count AS t1
  INNER JOIN tb_seller_prod_count AS t2
    ON t1.seller_id = t2.seller_id
),

-- 12 Listagem de produtos distintos vendidos pelos seller_id
tb_distinct_seller_prod_description AS (
    SELECT DISTINCT
        seller_id
        , product_id
        , product_description_length
        , product_photos_qty
        , product_weight_kg
    FROM tb_itens
),

-- 13 Cálculo de métricas de descrição e fotos de produtos (10)
tb_atributos_produtos AS (
    SELECT
        seller_id
        , MEAN(product_description_length) AS vlMediaCaracteresDescricao
        , MIN(product_description_length) AS vlMinCaracteresDescricao
        , PERCENTILE(product_description_length, 0.25) AS vlP25CaracteresDescricao
        , MEDIAN(product_description_length) AS vlMedianaCaracteresDescricao
        , PERCENTILE(product_description_length, 0.75) AS vlP75CaracteresDescricao
        , MAX(product_description_length) AS vlMaxCaracteresDescricao
        , MEAN(product_photos_qty) AS vlMediaFotosProduto
        , MEAN(product_weight_kg) AS vlMediaPesoPortfolio
        , MEDIAN(product_weight_kg) AS vlMedianaPesoPortfolio
        , PERCENTILE(product_weight_kg, 0.25) AS vlP25PesoPortfolio
        , PERCENTILE(product_weight_kg, 0.75) AS vlP75PesoPortfolio
        , MIN(product_weight_kg) AS vlMinPesoPortfolio
        , MAX(product_weight_kg) AS vlMaxPesoPortfolio
        , SUM(product_weight_kg) AS vlTotalPesoPortfolio
    FROM tb_distinct_seller_prod_description
    GROUP BY seller_id
),

-- 14 Receita e frete por janela
tb_seller_metrics AS (
  SELECT
    seller_id
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN COALESCE(price, 0) ELSE 0 END) AS vlReceitaTotD14
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN COALESCE(price, 0) ELSE 0 END) AS vlReceitaTotD28
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN COALESCE(price, 0) ELSE 0 END) AS vlReceitaTotD56
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN COALESCE(price, 0) ELSE 0 END) AS vlReceitaTotD365
    , SUM(COALESCE(price, 0)) AS vlReceitaTotVida

    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN COALESCE(freight_value, 0) ELSE 0 END) AS vlFreteTotD14
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN COALESCE(freight_value, 0) ELSE 0 END) AS vlFreteTotD28
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN COALESCE(freight_value, 0) ELSE 0 END) AS vlFreteTotD56
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN COALESCE(freight_value, 0) ELSE 0 END) AS vlFreteTotD365
    , SUM(COALESCE(freight_value, 0)) AS vlFreteTotVida

    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END) AS vlMediaPesoProdutoD14
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END) AS vlMediaPesoProdutoD28
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END) AS vlMediaPesoProdutoD56
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END) AS vlMediaPesoProdutoD365
    , MEAN(product_weight_kg) AS vlMediaPesoProdutoVida

    , MIN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END) AS vlMinPesoProdutoD14
    , MIN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END) AS vlMinPesoProdutoD28
    , MIN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END) AS vlMinPesoProdutoD56
    , MIN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END) AS vlMinPesoProdutoD365
    , MIN(product_weight_kg) AS vlMinPesoProdutoVida

    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END, 0.25) AS vlP25PesoProdutoD14
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END, 0.25) AS vlP25PesoProdutoD28
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END, 0.25) AS vlP25PesoProdutoD56
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END, 0.25) AS vlP25PesoProdutoD365
    , PERCENTILE(product_weight_kg, 0.25) AS vlP25PesoProdutoVida

    , MEDIAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END) AS vlMedianaPesoProdutoD14
    , MEDIAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END) AS vlMedianaPesoProdutoD28
    , MEDIAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END) AS vlMedianaPesoProdutoD56
    , MEDIAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END) AS vlMedianaPesoProdutoD365
    , MEDIAN(product_weight_kg) AS vlMedianaPesoProdutoVida

    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END, 0.75) AS vlP75PesoProdutoD14
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END, 0.75) AS vlP75PesoProdutoD28
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END, 0.75) AS vlP75PesoProdutoD56
    , PERCENTILE(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END, 0.75) AS vlP75PesoProdutoD365
    , PERCENTILE(product_weight_kg, 0.75) AS vlP75PesoProdutoVida

    , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg END) AS vlMaxPesoProdutoD14
    , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg END) AS vlMaxPesoProdutoD28
    , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg END) AS vlMaxPesoProdutoD56
    , MAX(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg END) AS vlMaxPesoProdutoD365
    , MAX(product_weight_kg) AS vlMaxPesoProdutoVida

    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_weight_kg ELSE 0 END) AS vlTotalPesoProdutoD14
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_weight_kg ELSE 0 END) AS vlTotalPesoProdutoD28
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_weight_kg ELSE 0 END) AS vlTotalPesoProdutoD56
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_weight_kg ELSE 0 END) AS vlTotalPesoProdutoD365
    , SUM(product_weight_kg) AS vlTotalPesoProdutoVida

    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_cubic_volume_cm3 END) AS vlMediaCubagemProdutoD14
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_cubic_volume_cm3 END) AS vlMediaCubagemProdutoD28
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_cubic_volume_cm3 END) AS vlMediaCubagemProdutoD56
    , MEAN(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_cubic_volume_cm3 END) AS vlMediaCubagemProdutoD365
    , MEAN(product_cubic_volume_cm3) AS vlMediaCubagemProdutoVida

    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN product_cubic_volume_cm3 ELSE 0 END) AS vlTotalCubagemProdutoD14
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN product_cubic_volume_cm3 ELSE 0 END) AS vlTotalCubagemProdutoD28
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN product_cubic_volume_cm3 ELSE 0 END) AS vlTotalCubagemProdutoD56
    , SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN product_cubic_volume_cm3 ELSE 0 END) AS vlTotalCubagemProdutoD365
    , SUM(product_cubic_volume_cm3) AS vlTotalCubagemProdutoVida
  FROM tb_itens
  GROUP BY seller_id
),

-- 15 tb_indicadores_por_kg (14)
tb_indicadores_por_kg AS (
  SELECT
    seller_id
    , vlReceitaTotD14 / NULLIF(vlTotalPesoProdutoD14, 0) AS vlPrecoKgD14
    , vlReceitaTotD28 / NULLIF(vlTotalPesoProdutoD28, 0) AS vlPrecoKgD28
    , vlReceitaTotD56 / NULLIF(vlTotalPesoProdutoD56, 0) AS vlPrecoKgD56
    , vlReceitaTotD365 / NULLIF(vlTotalPesoProdutoD365, 0) AS vlPrecoKgD365
    , vlReceitaTotVida / NULLIF(vlTotalPesoProdutoVida, 0) AS vlPrecoKgVida

    , vlFreteTotD14 / NULLIF(vlTotalPesoProdutoD14, 0) AS vlFreteKgD14
    , vlFreteTotD28 / NULLIF(vlTotalPesoProdutoD28, 0) AS vlFreteKgD28
    , vlFreteTotD56 / NULLIF(vlTotalPesoProdutoD56, 0) AS vlFreteKgD56
    , vlFreteTotD365 / NULLIF(vlTotalPesoProdutoD365, 0) AS vlFreteKgD365
    , vlFreteTotVida / NULLIF(vlTotalPesoProdutoVida, 0) AS vlFreteKgVida
  FROM tb_seller_metrics
),

-- 16 Lista de sellers distintos
tb_sellers AS (
  SELECT DISTINCT
    seller_id
  FROM tb_itens
),

-- 17 Receita por seller e categoria de produto
tb_cat_receita AS (
  SELECT
    seller_id,
    product_category_name,

    SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 14) THEN COALESCE(price, 0) ELSE 0 END) AS vlTotalReceitaD14,
    SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN COALESCE(price, 0) ELSE 0 END) AS vlTotalReceitaD28,
    SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN COALESCE(price, 0) ELSE 0 END) AS vlTotalReceitaD56,
    SUM(CASE WHEN order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN COALESCE(price, 0) ELSE 0 END) AS vlTotalReceitaD365,
    SUM(COALESCE(price, 0)) AS vlTotalReceitaVida

  FROM tb_itens
  GROUP BY seller_id, product_category_name
),

-- 18 Forma longa de tabela seller x product_category_name x janela x receita (17)
tb_cat_janela AS (
  SELECT seller_id, product_category_name, 'D14' AS janela, vlTotalReceitaD14 AS vlReceitaCategoria FROM tb_cat_receita
  UNION ALL

  SELECT seller_id, product_category_name, 'D28' AS janela, vlTotalReceitaD28 AS vlReceitaCategoria FROM tb_cat_receita
  UNION ALL

  SELECT seller_id, product_category_name, 'D56' AS janela, vlTotalReceitaD56 AS vlReceitaCategoria FROM tb_cat_receita
  UNION ALL

  SELECT seller_id, product_category_name, 'D365' AS janela, vlTotalReceitaD365 AS vlReceitaCategoria FROM tb_cat_receita
  UNION ALL

  SELECT seller_id, product_category_name, 'Vida' AS janela, vlTotalReceitaVida AS vlReceitaCategoria FROM tb_cat_receita
),

-- 19 Tabela base para gerar ranking. Cálculo de receita total por seller_id e janela (18)
tb_rank_base AS (
  SELECT
    seller_id,
    product_category_name,
    janela,
    vlReceitaCategoria,

    SUM(vlReceitaCategoria) OVER (PARTITION BY seller_id, janela) AS vlReceitaSellerJanela

  FROM tb_cat_janela
  WHERE vlReceitaCategoria > 0
),

-- 20 Ranking de categoria por seller_id e janela. Cálculo de share
tb_rank AS (
  SELECT
    seller_id,
    product_category_name,
    janela,
    vlReceitaCategoria,
    vlReceitaSellerJanela,

    vlReceitaCategoria / vlReceitaSellerJanela AS shareReceitaCategoria,

    ROW_NUMBER() OVER (PARTITION BY seller_id, janela ORDER BY vlReceitaCategoria DESC, product_category_name ASC) AS nrRankCategoria

  FROM tb_rank_base
),

-- 21 Tabela com top categorias e share por janela (21)
tb_top_categorias AS (
  SELECT
    t1.seller_id

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 1 THEN t2.product_category_name END) AS descTopCategoria1D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 1 THEN t2.product_category_name END) AS descTopCategoria1D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 1 THEN t2.product_category_name END) AS descTopCategoria1D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 1 THEN t2.product_category_name END) AS descTopCategoria1D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 1 THEN t2.product_category_name END) AS descTopCategoria1Vida

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 2 THEN t2.product_category_name END) AS descTopCategoria2D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 2 THEN t2.product_category_name END) AS descTopCategoria2D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 2 THEN t2.product_category_name END) AS descTopCategoria2D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 2 THEN t2.product_category_name END) AS descTopCategoria2D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 2 THEN t2.product_category_name END) AS descTopCategoria2Vida

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 3 THEN t2.product_category_name END) AS descTopCategoria3D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 3 THEN t2.product_category_name END) AS descTopCategoria3D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 3 THEN t2.product_category_name END) AS descTopCategoria3D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 3 THEN t2.product_category_name END) AS descTopCategoria3D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 3 THEN t2.product_category_name END) AS descTopCategoria3Vida

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 1 THEN t2.shareReceitaCategoria END) AS shareTopCategoria1D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 1 THEN t2.shareReceitaCategoria END) AS shareTopCategoria1D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 1 THEN t2.shareReceitaCategoria END) AS shareTopCategoria1D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 1 THEN t2.shareReceitaCategoria END) AS shareTopCategoria1D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 1 THEN t2.shareReceitaCategoria END) AS shareTopCategoria1Vida

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 2 THEN t2.shareReceitaCategoria END) AS shareTopCategoria2D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 2 THEN t2.shareReceitaCategoria END) AS shareTopCategoria2D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 2 THEN t2.shareReceitaCategoria END) AS shareTopCategoria2D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 2 THEN t2.shareReceitaCategoria END) AS shareTopCategoria2D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 2 THEN t2.shareReceitaCategoria END) AS shareTopCategoria2Vida

    , MAX(CASE WHEN t2.janela = 'D14' AND t2.nrRankCategoria = 3 THEN t2.shareReceitaCategoria END) AS shareTopCategoria3D14
    , MAX(CASE WHEN t2.janela = 'D28' AND t2.nrRankCategoria = 3 THEN t2.shareReceitaCategoria END) AS shareTopCategoria3D28
    , MAX(CASE WHEN t2.janela = 'D56' AND t2.nrRankCategoria = 3 THEN t2.shareReceitaCategoria END) AS shareTopCategoria3D56
    , MAX(CASE WHEN t2.janela = 'D365' AND t2.nrRankCategoria = 3 THEN t2.shareReceitaCategoria END) AS shareTopCategoria3D365
    , MAX(CASE WHEN t2.janela = 'Vida' AND t2.nrRankCategoria = 3 THEN t2.shareReceitaCategoria END) AS shareTopCategoria3Vida

  FROM tb_sellers AS t1
  LEFT JOIN tb_rank AS t2
    ON t1.seller_id = t2.seller_id
    AND t2.nrRankCategoria <= 3
  GROUP BY t1.seller_id
),

tb_product_feature_store AS (
  SELECT
    t1.seller_id as idSeller

    -- Diversidade de catálogo
    , t1.vlCategoriasDistintasD14
    , t1.vlCategoriasDistintasD28
    , t1.vlCategoriasDistintasD56
    , t1.vlCategoriasDistintasD365
    , t1.vlCategoriasDistintasVida
    , t1.vlProdutosDistintosD14
    , t1.vlProdutosDistintosD28
    , t1.vlProdutosDistintosD56
    , t1.vlProdutosDistintosD365
    , t1.vlProdutosDistintosVida

    -- Concorrência entre sellers
    , t2.vlContagemCategoriaConcorrentesD14
    , t2.vlContagemCategoriaConcorrentesD28
    , t2.vlContagemCategoriaConcorrentesD56
    , t2.vlContagemCategoriaConcorrentesD365
    , t2.vlContagemCategoriaConcorrentesVida
    , t3.vlContagemProdutosConcorrentesD14
    , t3.vlContagemProdutosConcorrentesD28
    , t3.vlContagemProdutosConcorrentesD56
    , t3.vlContagemProdutosConcorrentesD365
    , t3.vlContagemProdutosConcorrentesVida

    -- Peso dos produtos
    , ROUND(t4.vlMediaPesoProdutoD14, 3) AS vlMediaPesoProdutoD14
    , ROUND(t4.vlMediaPesoProdutoD28, 3) AS vlMediaPesoProdutoD28
    , ROUND(t4.vlMediaPesoProdutoD56, 3) AS vlMediaPesoProdutoD56
    , ROUND(t4.vlMediaPesoProdutoD365, 3) AS vlMediaPesoProdutoD365
    , ROUND(t4.vlMediaPesoProdutoVida, 3) AS vlMediaPesoProdutoVida
    , ROUND(t4.vlMedianaPesoProdutoD14, 3) AS vlMedianaPesoProdutoD14
    , ROUND(t4.vlMedianaPesoProdutoD28, 3) AS vlMedianaPesoProdutoD28
    , ROUND(t4.vlMedianaPesoProdutoD56, 3) AS vlMedianaPesoProdutoD56
    , ROUND(t4.vlMedianaPesoProdutoD365, 3) AS vlMedianaPesoProdutoD365
    , ROUND(t4.vlMedianaPesoProdutoVida, 3) AS vlMedianaPesoProdutoVida
    , ROUND(t4.vlP25PesoProdutoD14, 3) AS vlP25PesoProdutoD14
    , ROUND(t4.vlP25PesoProdutoD28, 3) AS vlP25PesoProdutoD28
    , ROUND(t4.vlP25PesoProdutoD56, 3) AS vlP25PesoProdutoD56
    , ROUND(t4.vlP25PesoProdutoD365, 3) AS vlP25PesoProdutoD365
    , ROUND(t4.vlP25PesoProdutoVida, 3) AS vlP25PesoProdutoVida
    , ROUND(t4.vlP75PesoProdutoD14, 3) AS vlP75PesoProdutoD14
    , ROUND(t4.vlP75PesoProdutoD28, 3) AS vlP75PesoProdutoD28
    , ROUND(t4.vlP75PesoProdutoD56, 3) AS vlP75PesoProdutoD56
    , ROUND(t4.vlP75PesoProdutoD365, 3) AS vlP75PesoProdutoD365
    , ROUND(t4.vlP75PesoProdutoVida, 3) AS vlP75PesoProdutoVida
    , t4.vlMinPesoProdutoD14
    , t4.vlMinPesoProdutoD28
    , t4.vlMinPesoProdutoD56
    , t4.vlMinPesoProdutoD365
    , t4.vlMinPesoProdutoVida
    , t4.vlMaxPesoProdutoD14
    , t4.vlMaxPesoProdutoD28
    , t4.vlMaxPesoProdutoD56
    , t4.vlMaxPesoProdutoD365
    , t4.vlMaxPesoProdutoVida
    , ROUND(t4.vlTotalPesoProdutoD14, 3) AS vlTotalPesoProdutoD14
    , ROUND(t4.vlTotalPesoProdutoD28, 3) AS vlTotalPesoProdutoD28
    , ROUND(t4.vlTotalPesoProdutoD56, 3) AS vlTotalPesoProdutoD56
    , ROUND(t4.vlTotalPesoProdutoD365, 3) AS vlTotalPesoProdutoD365
    , ROUND(t4.vlTotalPesoProdutoVida, 3) AS vlTotalPesoProdutoVida

    -- Cubagem dos produtos
    , ROUND(t4.vlMediaCubagemProdutoD14, 1) AS vlMediaCubagemProdutoD14
    , ROUND(t4.vlMediaCubagemProdutoD28, 1) AS vlMediaCubagemProdutoD28
    , ROUND(t4.vlMediaCubagemProdutoD56, 1) AS vlMediaCubagemProdutoD56
    , ROUND(t4.vlMediaCubagemProdutoD365, 1) AS vlMediaCubagemProdutoD365
    , ROUND(t4.vlMediaCubagemProdutoVida, 1) AS vlMediaCubagemProdutoVida
    , ROUND(t4.vlTotalCubagemProdutoD14, 1) AS vlTotalCubagemProdutoD14
    , ROUND(t4.vlTotalCubagemProdutoD28, 1) AS vlTotalCubagemProdutoD28
    , ROUND(t4.vlTotalCubagemProdutoD56, 1) AS vlTotalCubagemProdutoD56
    , ROUND(t4.vlTotalCubagemProdutoD365, 1) AS vlTotalCubagemProdutoD365
    , ROUND(t4.vlTotalCubagemProdutoVida, 1) AS vlTotalCubagemProdutoVida

    -- Indicadores por kg
    , ROUND(t5.vlPrecoKgD14, 2) AS vlPrecoKgD14
    , ROUND(t5.vlPrecoKgD28, 2) AS vlPrecoKgD28
    , ROUND(t5.vlPrecoKgD56, 2) AS vlPrecoKgD56
    , ROUND(t5.vlPrecoKgD365, 2) AS vlPrecoKgD365
    , ROUND(t5.vlPrecoKgVida, 2) AS vlPrecoKgVida
    , ROUND(t5.vlFreteKgD14, 2) AS vlFreteKgD14
    , ROUND(t5.vlFreteKgD28, 2) AS vlFreteKgD28
    , ROUND(t5.vlFreteKgD56, 2) AS vlFreteKgD56
    , ROUND(t5.vlFreteKgD365, 2) AS vlFreteKgD365
    , ROUND(t5.vlFreteKgVida, 2) AS vlFreteKgVida

    -- Top 3 categorias do seller
    , t6.descTopCategoria1D14
    , t6.descTopCategoria1D28
    , t6.descTopCategoria1D56
    , t6.descTopCategoria1D365
    , t6.descTopCategoria1Vida
    , t6.descTopCategoria2D14
    , t6.descTopCategoria2D28
    , t6.descTopCategoria2D56
    , t6.descTopCategoria2D365
    , t6.descTopCategoria2Vida
    , t6.descTopCategoria3D14
    , t6.descTopCategoria3D28
    , t6.descTopCategoria3D56
    , t6.descTopCategoria3D365
    , t6.descTopCategoria3Vida
    , ROUND(t6.shareTopCategoria1D14, 3) AS shareTopCategoria1D14
    , ROUND(t6.shareTopCategoria1D28, 3) AS shareTopCategoria1D28
    , ROUND(t6.shareTopCategoria1D56, 3) AS shareTopCategoria1D56
    , ROUND(t6.shareTopCategoria1D365, 3) AS shareTopCategoria1D365
    , ROUND(t6.shareTopCategoria1Vida, 3) AS shareTopCategoria1Vida
    , ROUND(t6.shareTopCategoria2D14, 3) AS shareTopCategoria2D14
    , ROUND(t6.shareTopCategoria2D28, 3) AS shareTopCategoria2D28
    , ROUND(t6.shareTopCategoria2D56, 3) AS shareTopCategoria2D56
    , ROUND(t6.shareTopCategoria2D365, 3) AS shareTopCategoria2D365
    , ROUND(t6.shareTopCategoria2Vida, 3) AS shareTopCategoria2Vida
    , ROUND(t6.shareTopCategoria3D14, 3) AS shareTopCategoria3D14
    , ROUND(t6.shareTopCategoria3D28, 3) AS shareTopCategoria3D28
    , ROUND(t6.shareTopCategoria3D56, 3) AS shareTopCategoria3D56
    , ROUND(t6.shareTopCategoria3D365, 3) AS shareTopCategoria3D365
    , ROUND(t6.shareTopCategoria3Vida, 3) AS shareTopCategoria3Vida

    -- Atributos de produto
    , ROUND(t7.vlMediaCaracteresDescricao, 1) AS vlMediaCaracteresDescricao
    , ROUND(t7.vlMedianaCaracteresDescricao, 1) AS vlMedianaCaracteresDescricao
    , ROUND(t7.vlP25CaracteresDescricao, 1) AS vlP25CaracteresDescricao
    , ROUND(t7.vlP75CaracteresDescricao, 1) AS vlP75CaracteresDescricao
    , ROUND(t7.vlMinCaracteresDescricao, 1) AS vlMinCaracteresDescricao
    , ROUND(t7.vlMaxCaracteresDescricao, 1) AS vlMaxCaracteresDescricao
    , ROUND(t7.vlMediaFotosProduto, 1) AS vlMediaFotosProduto

    -- Peso do Portfólio do Seller
    , ROUND(t7.vlMediaPesoPortfolio, 3) AS vlMediaPesoPortfolio
    , ROUND(t7.vlMedianaPesoPortfolio, 3) AS vlMedianaPesoPortfolio
    , ROUND(t7.vlP25PesoPortfolio, 3) AS vlP25PesoPortfolio
    , ROUND(t7.vlP75PesoPortfolio, 3) AS vlP75PesoPortfolio
    , ROUND(t7.vlMinPesoPortfolio, 3) AS vlMinPesoPortfolio
    , ROUND(t7.vlMaxPesoPortfolio, 3) AS vlMaxPesoPortfolio
    , ROUND(t7.vlTotalPesoPortfolio, 3) AS vlTotalPesoPortfolio
  FROM tb_seller_cat_prod_count AS t1
  LEFT JOIN tb_category_competitity AS t2
    ON t1.seller_id = t2.seller_id
  LEFT JOIN tb_product_competitity AS t3
    ON t1.seller_id = t3.seller_id
  LEFT JOIN tb_seller_metrics AS t4
    ON t1.seller_id = t4.seller_id
  LEFT JOIN tb_indicadores_por_kg AS t5
    ON t1.seller_id = t5.seller_id
  LEFT JOIN tb_top_categorias AS t6
    ON t1.seller_id = t6.seller_id
  LEFT JOIN tb_atributos_produtos AS t7
    ON t1.seller_id = t7.seller_id
)

SELECT '{date}' AS dtRef,
       *
FROM tb_product_feature_store
ORDER BY idSeller;
