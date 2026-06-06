# Feature Store — Variáveis de Produtos

## Convenção de Nomenclatura

**Estrutura:** `[prefixo][Qualificador][Metrica][Periodo]`

### Prefixos

| Prefixo | Tipo de dado |
|---------|--------------|
| `vl` | Valor numérico |
| `desc` | Valor textual / descritivo |

### Qualificadores Estatísticos *(inseridos entre o prefixo e a métrica)*

| Qualificador | Significado |
|--------------|-------------|
| `Media` | Média aritmética |
| `Mediana` | Mediana |
| `25`, `75` | Percentis (ex.: `vl25Metrica`). O percentil 50 não é usado — equivale à `Mediana` |
| `Min` | Mínimo |
| `Max` | Máximo |
| `Total` | Soma acumulada |
| `Share` | Participação percentual |

### Sufixos de Período *(variáveis marcadas com `*` possuem as cinco versões)*

| Sufixo | Janela de tempo |
|--------|-----------------|
| `D14` | Últimos 14 dias |
| `D28` | Últimos 28 dias |
| `D56` | Últimos 56 dias |
| `D365` | Últimos 365 dias |
| `Vida` | Desde o primeiro registro (lifetime) |

> **Regra de corte (variáveis por janela):** `data_venda < hoje()` — população = produtos **vendidos** no período.
> **Regra de corte (variáveis de portfólio):** produtos **disponíveis/vinculados** ao seller em `hoje()` — snapshot atual, sem janela.

---

## Lista de Variáveis

### 1. Diversidade de Catálogo

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlCategoriasDistintas[D14\|D28\|D56\|D365\|Vida]` | Quantidade de categorias distintas no período |
| [ ] | `vlProdutosDistintos[D14\|D28\|D56\|D365\|Vida]` | Quantidade de produtos distintos no período |

### 2. Concorrência entre Sellers

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlContagemCategoriaConcorrentes[D14\|D28\|D56\|D365\|Vida]` | Sellers distintos que oferecem categorias em comum no período |
| [ ] | `vlContagemProdutosConcorrentes[D14\|D28\|D56\|D365\|Vida]` | Sellers distintos que oferecem os mesmos produtos no período |

### 3. Peso dos Produtos Vendidos *(por janela — produtos com venda no período)*

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaPesoProduto[D14\|D28\|D56\|D365\|Vida]` | Peso médio dos produtos vendidos no período |
| [ ] | `vlMedianaPesoProduto[D14\|D28\|D56\|D365\|Vida]` | Peso mediano dos produtos vendidos no período |
| [ ] | `vl25PesoProduto[D14\|D28\|D56\|D365\|Vida]` | Percentil 25 do peso dos produtos vendidos no período |
| [ ] | `vl75PesoProduto[D14\|D28\|D56\|D365\|Vida]` | Percentil 75 do peso dos produtos vendidos no período |
| [ ] | `vlMinPesoProduto[D14\|D28\|D56\|D365\|Vida]` | Peso mínimo dos produtos vendidos no período |
| [ ] | `vlMaxPesoProduto[D14\|D28\|D56\|D365\|Vida]` | Peso máximo dos produtos vendidos no período |
| [ ] | `vlTotalPesoProdutos[D14\|D28\|D56\|D365\|Vida]` | Peso total dos produtos vendidos no período |

### 4. Cubagem dos Produtos

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaCubagemProdutos[D14\|D28\|D56\|D365\|Vida]` | Cubagem média dos produtos no período |
| [ ] | `vlTotalCubagemProdutos[D14\|D28\|D56\|D365\|Vida]` | Cubagem total dos produtos no período |

### 5. Indicadores por Kg

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlPrecoKg[D14\|D28\|D56\|D365\|Vida]` | Receita total / massa total dos produtos no período (R$/kg) |
| [ ] | `vlFreteKg[D14\|D28\|D56\|D365\|Vida]` | Frete total / massa total dos produtos no período (R$/kg) |

### 6. Top 3 Categorias do Seller

> Três colunas separadas, uma por posição do ranking, determinado por quantidade vendida. Período aplicado a todas.

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `descTopCategoria1[D14\|D28\|D56\|D365\|Vida]` | Nome da 1ª categoria mais vendida do seller no período |
| [ ] | `descTopCategoria2[D14\|D28\|D56\|D365\|Vida]` | Nome da 2ª categoria mais vendida do seller no período |
| [ ] | `descTopCategoria3[D14\|D28\|D56\|D365\|Vida]` | Nome da 3ª categoria mais vendida do seller no período |
| [ ] | `vlShareTopCategoria1[D14\|D28\|D56\|D365\|Vida]` | Share (%) da 1ª categoria no período |
| [ ] | `vlShareTopCategoria2[D14\|D28\|D56\|D365\|Vida]` | Share (%) da 2ª categoria no período |
| [ ] | `vlShareTopCategoria3[D14\|D28\|D56\|D365\|Vida]` | Share (%) da 3ª categoria no período |

### 7. Atributos de Produto *(estáticos — sem sufixo de período)*

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaCaracteresDescricao` | Média de caracteres na descrição do produto |
| [ ] | `vlMedianaCaracteresDescricao` | Mediana de caracteres na descrição do produto |
| [ ] | `vl25CaracteresDescricao` | Percentil 25 de caracteres na descrição |
| [ ] | `vl75CaracteresDescricao` | Percentil 75 de caracteres na descrição |
| [ ] | `vlMinCaracteresDescricao` | Mínimo de caracteres na descrição |
| [ ] | `vlMaxCaracteresDescricao` | Máximo de caracteres na descrição |
| [ ] | `vlMediaFotosProduto` | Quantidade média de fotos por produto |

### 8. Peso do Portfólio do Seller *(estáticas — sem sufixo de período)*

> População = **todos os produtos disponíveis / vinculados** ao seller em `hoje()`, independentemente de terem venda.
> Diferença em relação à seção 3: aqui não há corte por venda nem janela; é um snapshot do catálogo atual.
> Distribuição calculada sobre o **peso unitário** de cada produto distinto do portfólio.

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaPesoPortfolio` | Peso médio dos produtos do portfólio do seller |
| [ ] | `vlMedianaPesoPortfolio` | Peso mediano dos produtos do portfólio do seller |
| [ ] | `vl25PesoPortfolio` | Percentil 25 do peso dos produtos do portfólio |
| [ ] | `vl75PesoPortfolio` | Percentil 75 do peso dos produtos do portfólio |
| [ ] | `vlMinPesoPortfolio` | Peso mínimo entre os produtos do portfólio |
| [ ] | `vlMaxPesoPortfolio` | Peso máximo entre os produtos do portfólio |
| [ ] | `vlTotalPesoPortfolio` | Peso total do portfólio (soma dos pesos unitários dos produtos distintos) |
