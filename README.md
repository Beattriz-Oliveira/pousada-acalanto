# Pousada Acalanto: Análise de Desempenho Financeiro e Perfil de Clientes

Projeto de análise de dados end-to-end que analisa e diagnostica o desempenho financeiro e o perfil de clientes de uma pousada fictícia com loja integrada, cobrindo desde a modelagem do banco de dados em MySQL até a visualização final em Power BI.

<a href="https://app.powerbi.com/view?r=eyJrIjoiNDA1MjM1MjUtN2IzNC00MDRhLWI1YzgtYWM1NTRhZjg2ZjBmIiwidCI6IjkwNzg5MzgzLTExYjMtNGQ0My05YjI4LWNlNDM1M2IyZDg1NSJ9" target="_blank">
  <img src="assets/Gif - Acalanto.gif" alt="Demonstração do Dashboard" width="100%">
</a>

---

## 🔗 Acesso ao Projeto

| Recurso | Link |
|---|---|
| 📊 Dashboard | [Acessar no Power BI](https://app.powerbi.com/view?r=eyJrIjoiNDA1MjM1MjUtN2IzNC00MDRhLWI1YzgtYWM1NTRhZjg2ZjBmIiwidCI6IjkwNzg5MzgzLTExYjMtNGQ0My05YjI4LWNlNDM1M2IyZDg1NSJ9) |
| 🗂️ Banco de dados | `sql/banco_acalanto.sql` |
| ⚙️ DBA | `sql/DBA.sql` |
| 🐍 Geração de dados | `src/data_entry.py` |
| 🔄 ETL | `src/etl.py` |

---

## 📋 Sobre o Projeto

O objetivo foi construir uma solução de BI completa integrando três áreas: Arquitetura de Dados, DBA e Business Intelligence. A Pousada Acalanto é um negócio fictício com dois domínios distintos — hospedagem e loja — que o projeto modela, popula e analisa de forma integrada.

O dashboard responde quatro perguntas de negócio:

1. **Qual é a saúde financeira consolidada da pousada?**
2. **Como está o desempenho da hospedagem por tipo de quarto e evolução ao longo dos anos?**
3. **Onde estão o lucro e os riscos de estoque da loja?**
4. **Quem são os clientes e quais deles geram mais valor?**

Cada página foi desenhada para responder exatamente a uma dessas perguntas, sem sobreposição de informação entre elas.

### Funcionalidades e Escopo

- Modelagem dimensional completa (DER → SQL) com duas tabelas fato e dimensões conformadas
- Banco de dados MySQL com índices, views analíticas, stored procedures e triggers de controle de estoque
- Pipeline de geração de dados fictícios em Python com a biblioteca Faker (600 clientes, 4 anos de dados)
- ETL com padronização de telefones, log de execução e rollback automático em caso de erro
- Dashboard de 4 páginas com drill-through, bookmarks, dicas de ferramenta enriquecidas e títulos dinâmicos via DAX

> **Nota sobre os dados:** os dados foram gerados de forma aleatória com a biblioteca Faker para fins de demonstração técnica. Por essa razão, o projeto foca em análise de desempenho histórico e diagnóstico — e não em tendências ou operacional em tempo real, que requerem dados com padrões reais e atualização contínua. Essa limitação está documentada como decisão consciente de escopo.

---

## 🏗️ Arquitetura

```
DER (MySQL Workbench)
        │
        ▼
01_banco_acalanto.sql  ──►  Tabelas, FKs, check constraints
        │
        ▼
data_entry.py  ──►  Faker pt_BR — 600 clientes, hospedagens, vendas (2022–2026)
        │
        ▼
etl.py  ──►  Padronização de telefones + log em etl_log
        │
        ▼
02_dba.sql  ──►  Índices + Views analíticas + Procedures + Triggers
        │
        ▼
Power BI  ──►  Modelo estrela + DAX + Dashboard
```

### Estrutura de Dados

| Entidade | Papel | Observação |
|---|---|---|
| `fHospedagem` | Fato | Hospedagens finalizadas com valor e qtde de dias |
| `fVenda` | Fato | Transações da loja com receita, custo e lucro |
| `dCliente` | Dimensão | Nome, CPF formatado, telefone, cidade, estado |
| `dQuarto` | Dimensão | Tipo, valor de diária e capacidade unidos |
| `dProduto` | Dimensão | Produto com categoria, subcategoria e status de estoque |
| `dCalendario` | Dimensão | Tabela de datas com ano, mês, trimestre e dia da semana |
| `vw_ficha_hospede` | View analítica | Perfil consolidado de cada hóspede com tipo de cliente |
| `vw_vendas` | View analítica | Vendas com lucro bruto, margem e forma de pagamento |

### Grain das tabelas fato

| Tabela | Grain |
|---|---|
| `fHospedagem` | 1 linha = 1 hospedagem finalizada |
| `fVenda` | 1 linha = 1 transação de venda |

---

## 📊 Estrutura do Dashboard

### Visão Executiva
Saúde financeira consolidada da pousada — Demonstração de Resultados, KPIs comparativos com ano anterior, receita por domínio e ranking de categorias com bookmark alternando entre "Categorias Lucrativas" e "Quartos de Maior Receita".

### Análise Pousada
Desempenho da hospedagem — receita e média de dias por tipo de quarto, evolução da receita e ticket médio ao longo dos anos, mapa de hóspedes por estado com dica de ferramenta detalhada por estado.

### Análise Loja
Desempenho comercial — lucro bruto por categoria, receita por forma de pagamento com dica de ferramenta rica (característica, perfil de cliente, melhor categoria), gráfico de tendência mensal, controle de estoque com formatação condicional de alertas e dica de ferramenta com top/bottom 3 produtos por lucro.

### Análise Clientes
Comportamento e perfil — segmentação por fidelização (Fidelizado / Regular / Visitante), faturamento e ticket médio por tipo de cliente, evolução de cadastros por mês, matriz consultável com drill-through para ficha detalhada individual.

### Ficha do Hóspede (drill-through)
Visão 360° por cliente — resumo financeiro (hospedagem + loja), informações de contato com CPF mascarado, histórico de estadias, quarto preferido e compras por categoria na loja.

---

## 🔍 Achados de Negócio

**1. A loja gera 2,5x mais receita que a hospedagem.** A loja representa 71% da receita total da pousada (R$2,88M vs R$1,17M), tornando o desempenho comercial o principal motor financeiro do negócio.

**2. Roupas concentra 24% do lucro bruto da loja.** Com R$1,47M de lucro bruto, a categoria Roupas lidera com margem superior às demais, seguida por Higiene e Bebidas.

**3. Quartos de luxo lideram em receita mas duplo tem a maior permanência.** Hóspedes de quarto duplo ficam em média 13,5 dias — quase o dobro dos demais tipos — indicando perfis distintos de uso entre os tipos de quarto.

**4. 96% dos hóspedes são visitantes únicos.** Com apenas 14 clientes fidelizados e 7 regulares em uma base de 395, há uma oportunidade clara de programas de fidelização — clientes fidelizados têm ticket médio de R$4.053M contra R$1.064M dos visitantes.

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Finalidade |
|---|---|
| MySQL 8+ | Banco de dados relacional, modelagem e DBA |
| Python + Faker | Geração de dados fictícios em pt_BR |
| mysql-connector-python | Conexão Python → MySQL |
| python-dotenv | Gestão segura de credenciais |
| Power BI Desktop | Modelagem dimensional, DAX e visualização |
| MySQL Workbench | Modelagem visual (DER) e Forward Engineering |
| Git / GitHub | Versionamento do projeto |

---

## 🏗️ Estrutura do Repositório

```
acalanto/
├── .gitignore
├── README.md
├── requirements.txt
│
├── assets/
│   └── thumbnail.png             # Imagem de apresentação do projeto
│
├── docs/
│   ├── DER_Acalanto.pdf.png      # Diagrama Entidade-Relacionamento
│   └── DRE.mwb                   # Modelo do banco de dados
│
├── sql/
│   ├── banco_acalanto.sql    # Criação do banco, tabelas e constraints
│   └── DBA.sql               # Índices, views, procedures e triggers
│
└── src/
    ├── data_entry.py            # Geração de dados com Faker
    └── etl.py                   # Padronização de telefones e log 
```

---

## Ordem de Execução

| Etapa | Arquivo | O que faz |
|---|---|---|
| 1 | `sql/banco_acalanto.sql` | Cria o banco e todas as tabelas |
| 2 | `src/data_entry.py` | Popula o banco com dados fictícios |
| 3 | `src/etl.py` | Padroniza e limpa os dados |
| 4 | `sql/DBA.sql` | Cria índices, views, procedures e triggers |

---

## ⚠️ Decisões de Design Documentadas

**Por que não dashboard operacional?** Dashboards operacionais dependem de atualização contínua dos dados. Como os dados são gerados uma única vez pelo script Faker, o projeto adota análise histórica — mais honesta com a natureza estática dos dados.

**Por que não análise de tendências?** Dados gerados com distribuição uniforme aleatória não produzem padrões sazonais reais. Forçar análise de tendência sobre esses dados geraria insights espúrios. Essa limitação seria superada com dados reais coletados ao longo do tempo.

**Custo operacional da pousada não modelado.** O projeto registra receita de hospedagem mas não custos fixos operacionais (salários, energia, manutenção). O "Lucro Líquido" na Demonstração de Resultados representa Lucro Bruto da Loja + Receita de Hospedagem — uma aproximação documentada, não um lucro contábil completo.

**Data de referência fixa: 2026-05-27.** Usada nas views SQL e nas medidas DAX para simular um ponto temporal operacional consistente para o projeto.

---

## 🐛 Decisões Técnicas e Problemas Resolvidos

| Problema | Causa | Correção |
|---|---|---|
| Hospedagens com status incorreto | Status gerado aleatoriamente sem validação de datas | CASE WHEN nas views corrigindo status pelo cruzamento de datas |
| CPF gerado com 14 caracteres | Faker pt_BR retorna CPF formatado com pontos e traço | `.replace('.','').replace('-','')` antes do INSERT |
| Constraints FK com nomes duplicados | Workbench gera nomes genéricos (id_quarto) reusados | Padrão `fk_[tabela]_[referencia]` aplicado em todo o script |
| Granularidade errada nas views | JOIN de quarto via reserva excluía hospedagens sem reserva | JOIN refeito via hospedagem diretamente |
| Estoque negativo possível | Sem validação antes do INSERT em itens_venda | Trigger `trg_valida_estoque` com SIGNAL antes da inserção |

---

## 👩‍💻 Autoria

* **Analista:** Beattriz Oliveira Sant'ana
* **Segmento:** Analista de Dados
* **Foco:** Data Architecture · DBA · Business Intelligence
* **Ano:** 2026