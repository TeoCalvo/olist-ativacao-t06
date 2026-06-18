
WITH tb_pedidos AS (
  SELECT *
  FROM workspace.olist.orders
  WHERE order_purchase_timestamp < '{date}'
),

tb_seller AS (
  SELECT
    order_id,
    seller_id
  FROM workspace.olist.order_items
  GROUP BY order_id, seller_id
),

tb_pagamentos AS (
  SELECT
    order_id,
    -- Valor por meio de pagamento
    SUM(CASE WHEN payment_type = 'credit_card'                                                    THEN payment_value ELSE 0 END) AS vlr_credit_card,
    SUM(CASE WHEN payment_type = 'boleto'                                                         THEN payment_value ELSE 0 END) AS vlr_boleto,
    SUM(CASE WHEN payment_type = 'voucher'                                                        THEN payment_value ELSE 0 END) AS vlr_voucher,
    SUM(CASE WHEN payment_type = 'debit_card'                                                     THEN payment_value ELSE 0 END) AS vlr_debit_card,
    SUM(CASE WHEN payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')          THEN payment_value ELSE 0 END) AS vlr_outros,
    -- Quantidade por meio de pagamento
    SUM(CASE WHEN payment_type = 'credit_card'                                                    THEN 1 ELSE 0 END) AS qtde_credit_card,
    SUM(CASE WHEN payment_type = 'boleto'                                                         THEN 1 ELSE 0 END) AS qtde_boleto,
    SUM(CASE WHEN payment_type = 'voucher'                                                        THEN 1 ELSE 0 END) AS qtde_voucher,
    SUM(CASE WHEN payment_type = 'debit_card'                                                     THEN 1 ELSE 0 END) AS qtde_debit_card,
    SUM(CASE WHEN payment_type NOT IN ('credit_card', 'boleto', 'voucher', 'debit_card')          THEN 1 ELSE 0 END) AS qtde_outros,
    -- Parcelamento
    MAX(CASE WHEN payment_installments > 0 THEN payment_installments END)                                            AS max_payment_installments
  FROM workspace.olist.order_payments
  GROUP BY order_id
),

tb_base AS (
  SELECT
    s.seller_id,
    p.order_purchase_timestamp,
    -- Valor
    pg.vlr_credit_card,
    pg.vlr_boleto,
    pg.vlr_voucher,
    pg.vlr_debit_card,
    pg.vlr_outros,
    -- Quantidade
    pg.qtde_credit_card,
    pg.qtde_boleto,
    pg.qtde_voucher,
    pg.qtde_debit_card,
    pg.qtde_outros,
    -- Parcelamento
    pg.max_payment_installments
  FROM tb_pedidos p
  INNER JOIN tb_seller     s  ON p.order_id = s.order_id
  LEFT  JOIN tb_pagamentos pg ON p.order_id = pg.order_id
),

tb_agg (

    SELECT
      b.seller_id AS idSeller,
      -- -------------------------------------------------------
      -- Valor médio por meio de pagamento
      -- -------------------------------------------------------
      -- D28
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.vlr_credit_card END) AS avgVlrCreditCardD28,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.vlr_boleto      END) AS avgVlrBoletoD28,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.vlr_voucher     END) AS avgVlrVoucherD28,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.vlr_debit_card  END) AS avgVlrDebitCardD28,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.vlr_outros      END) AS avgVlrOutrosD28,
      -- D56
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.vlr_credit_card END) AS avgVlrCreditCardD56,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.vlr_boleto      END) AS avgVlrBoletoD56,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.vlr_voucher     END) AS avgVlrVoucherD56,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.vlr_debit_card  END) AS avgVlrDebitCardD56,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.vlr_outros      END) AS avgVlrOutrosD56,
      -- D365
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card END) AS avgVlrCreditCardD365,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_boleto      END) AS avgVlrBoletoD365,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_voucher     END) AS avgVlrVoucherD365,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_debit_card  END) AS avgVlrDebitCardD365,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_outros      END) AS avgVlrOutrosD365,
      -- Vida
      AVG(b.vlr_credit_card) AS avgVlrCreditCardVida,
      AVG(b.vlr_boleto)      AS avgVlrBoletoVida,
      AVG(b.vlr_voucher)     AS avgVlrVoucherVida,
      AVG(b.vlr_debit_card)  AS avgVlrDebitCardVida,
      AVG(b.vlr_outros)      AS avgVlrOutrosVida,

      -- -------------------------------------------------------
      -- Parcelamento médio
      -- -------------------------------------------------------
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28)  THEN b.max_payment_installments END) AS avgPaymentInstallmentsD28,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56)  THEN b.max_payment_installments END) AS avgPaymentInstallmentsD56,
      AVG(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.max_payment_installments END) AS avgPaymentInstallmentsD365,
      AVG(b.max_payment_installments)                                                                               AS avgPaymentInstallmentsVida,

      -- -------------------------------------------------------
      -- Share de quantidade por meio de pagamento
      -- -------------------------------------------------------
      -- D28
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeCreditCardD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeBoletoD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeVoucherD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeDebitCardD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeOutrosD28,
      -- D56
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeCreditCardD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeBoletoD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeVoucherD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeDebitCardD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeOutrosD56,
      -- D365
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeCreditCardD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeBoletoD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeVoucherD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeDebitCardD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros END), 0) AS shareQtdeOutrosD365,
      -- Vida
      SUM(b.qtde_credit_card) / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS shareQtdeCreditCardVida,
      SUM(b.qtde_boleto)      / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS shareQtdeBoletoVida,
      SUM(b.qtde_voucher)     / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS shareQtdeVoucherVida,
      SUM(b.qtde_debit_card)  / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS shareQtdeDebitCardVida,
      SUM(b.qtde_outros)      / NULLIF(SUM(b.qtde_credit_card + b.qtde_boleto + b.qtde_voucher + b.qtde_debit_card + b.qtde_outros), 0) AS shareQtdeOutrosVida,

      -- -------------------------------------------------------
      -- Share de valor por meio de pagamento
      -- -------------------------------------------------------
      -- D28
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorCreditCardD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorBoletoD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorVoucherD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorDebitCardD28,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 28) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorOutrosD28,
      -- D56
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorCreditCardD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorBoletoD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorVoucherD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorDebitCardD56,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 56) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorOutrosD56,
      -- D365
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorCreditCardD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_boleto      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorBoletoD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_voucher     END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorVoucherD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_debit_card  END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorDebitCardD365,
      SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_outros      END) / NULLIF(SUM(CASE WHEN b.order_purchase_timestamp >= DATE_SUB('{date}', 365) THEN b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros END), 0) AS shareValorOutrosD365,
      -- Vida
      SUM(b.vlr_credit_card) / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS shareValorCreditCardVida,
      SUM(b.vlr_boleto)      / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS shareValorBoletoVida,
      SUM(b.vlr_voucher)     / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS shareValorVoucherVida,
      SUM(b.vlr_debit_card)  / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS shareValorDebitCardVida,
      SUM(b.vlr_outros)      / NULLIF(SUM(b.vlr_credit_card + b.vlr_boleto + b.vlr_voucher + b.vlr_debit_card + b.vlr_outros), 0) AS shareValorOutrosVida

    FROM  tb_base b

    GROUP BY seller_id
)

SELECT '{date}' AS dtRef,
       *
FROM tb_agg