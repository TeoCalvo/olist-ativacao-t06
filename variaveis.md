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
| `25`, `50`, `75` | Percentis (ex.: `vl25Metrica`) |
| `Min` | Mínimo |
| `Max` | Máximo |
| `Total` | Soma acumulada |
| `Share` | Participação percentual |

### Sufixos de Período *(variáveis marcadas com `*` possuem as quatro versões)*

| Sufixo | Janela de tempo |
|--------|-----------------|
| `D28` | Últimos 28 dias |
| `D56` | Últimos 56 dias |
| `D365` | Últimos 365 dias |
| `Vida` | Desde o primeiro registro (lifetime) |

> **Regra de corte:** `data_venda < hoje()`

---

## Lista de Variáveis

### 1. Diversidade de Catálogo

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlCategoriasDistintas[D28\|D56\|D365\|Vida]` | Quantidade de categorias distintas no período |
| [ ] | `vlProdutosDistintos[D28\|D56\|D365\|Vida]` | Quantidade de produtos distintos no período |

### 2. Concorrência entre Sellers

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlContagemCategoriaConcorrentes[D28\|D56\|D365\|Vida]` | Sellers distintos que oferecem categorias em comum no período |
| [ ] | `vlContagemProdutosConcorrentes[D28\|D56\|D365\|Vida]` | Sellers distintos que oferecem os mesmos produtos no período |

### 3. Atributos de Produto *(estáticos — sem sufixo de período)*

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaCaracteresDescricao` | Média de caracteres na descrição do produto |
| [ ] | `vlMedianaCaracteresDescricao` | Mediana de caracteres na descrição do produto |
| [ ] | `vl25CaracteresDescricao` | Percentil 25 de caracteres na descrição |
| [ ] | `vl50CaracteresDescricao` | Percentil 50 de caracteres na descrição |
| [ ] | `vl75CaracteresDescricao` | Percentil 75 de caracteres na descrição |
| [ ] | `vlMinCaracteresDescricao` | Mínimo de caracteres na descrição |
| [ ] | `vlMaxCaracteresDescricao` | Máximo de caracteres na descrição |
| [ ] | `vlMediaFotosProduto` | Quantidade média de fotos por produto |

### 4. Peso dos Produtos

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaPesoProduto[D28\|D56\|D365\|Vida]` | Peso médio dos produtos no período |
| [ ] | `vlMedianaPesoProduto[D28\|D56\|D365\|Vida]` | Peso mediano dos produtos no período |
| [ ] | `vl25PesoProduto[D28\|D56\|D365\|Vida]` | Percentil 25 do peso dos produtos no período |
| [ ] | `vl50PesoProduto[D28\|D56\|D365\|Vida]` | Percentil 50 do peso dos produtos no período |
| [ ] | `vl75PesoProduto[D28\|D56\|D365\|Vida]` | Percentil 75 do peso dos produtos no período |
| [ ] | `vlMinPesoProduto[D28\|D56\|D365\|Vida]` | Peso mínimo dos produtos no período |
| [ ] | `vlMaxPesoProduto[D28\|D56\|D365\|Vida]` | Peso máximo dos produtos no período |
| [ ] | `vlTotalPesoProdutos[D28\|D56\|D365\|Vida]` | Peso total dos produtos vendidos no período |

### 5. Cubagem dos Produtos

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlMediaCubagemProdutos[D28\|D56\|D365\|Vida]` | Cubagem média dos produtos no período |
| [ ] | `vlTotalCubagemProdutos[D28\|D56\|D365\|Vida]` | Cubagem total dos produtos no período |

### 6. Indicadores por Kg

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `vlPrecoKg[D28\|D56\|D365\|Vida]` | Receita total / massa total dos produtos no período (R$/kg) |
| [ ] | `vlFreteKg[D28\|D56\|D365\|Vida]` | Frete total / massa total dos produtos no período (R$/kg) |

### 7. Top 3 Categorias do Seller

> Três colunas separadas, uma por posição do ranking, determinado por quantidade vendida. Período aplicado a todas.

| Status | Variável | Descrição |
|--------|----------|-----------|
| [ ] | `descTopCategoria1[D28\|D56\|D365\|Vida]` | Nome da 1ª categoria mais vendida do seller no período |
| [ ] | `descTopCategoria2[D28\|D56\|D365\|Vida]` | Nome da 2ª categoria mais vendida do seller no período |
| [ ] | `descTopCategoria3[D28\|D56\|D365\|Vida]` | Nome da 3ª categoria mais vendida do seller no período |
| [ ] | `vlShareTopCategoria1[D28\|D56\|D365\|Vida]` | Share (%) da 1ª categoria no período |
| [ ] | `vlShareTopCategoria2[D28\|D56\|D365\|Vida]` | Share (%) da 2ª categoria no período |
| [ ] | `vlShareTopCategoria3[D28\|D56\|D365\|Vida]` | Share (%) da 3ª categoria no período |
