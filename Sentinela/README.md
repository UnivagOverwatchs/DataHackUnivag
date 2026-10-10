# Sentinela — Rota do Diploma

DataHack Univag 2026. De cada 100 que entram numa graduação em Mato Grosso, quantos chegam ao diploma, e em quais cursos a rota se perde?

## Stack

PostgreSQL 18 · Python (pandas, openpyxl, psycopg) · Power BI. A justificativa está em [doc/estrategia.md](doc/estrategia.md).

## Como rodar do zero

1. Instalar Python 3 e PostgreSQL.
2. `pip install -r requirements.txt`
3. Copiar `.env.example` para `.env` e preencher o acesso ao banco.
4. Baixar as bases para `Dados/` (a pasta não vai para o Git), nestas subpastas:
   - `Dados/INEP/censo_superior/` — Censo da Educação Superior, cursos e IES, 2021 a 2024
   - `Dados/INEP/trajetoria/` — Indicadores de Trajetória, turmas de 2015 a 2020
   - `Dados/INEP/indicadores_qualidade/` — CPC, Conceito Enade, IDD e IGC 2021–2023 e Enade Licenciaturas
   - `Dados/IBGE/sidra/` — tabela 9514 (população por idade, municípios de MT)
5. Criar as camadas: rodar `src/sql/00_schemas.sql` no banco.
6. Exploração (Fase 1), cada script grava o resultado em `src/outputs/`:
   - `python src/01_exploracao_censo.py` — perfil dos CSV do Censo
   - `python src/02_exploracao_planilhas.py` — abas e cabeçalhos das planilhas e do JSON
   - `python src/03_exploracao_trajetoria.py` — perfil da Trajetória em MT e taxas de junção (leva alguns minutos)
   - `python src/03b_exploracao_tipos_nulos.py` — tipo e quantidade de vazios de cada coluna, recorte de MT (leva alguns minutos)
7. Carga no banco (Fase 2): `python src/04_carga_raw.py` — leva para o schema `raw` as bases de P1 a P5 (Trajetória, Censo de cursos 2021–2024, CPC e Enade Licenciaturas), as de apoio (Censo de instituições, IGC, IDD e Conceito Enade 2021–2023) e a população por idade do IBGE, usada no bônus B1. Com `--so-mt` carrega só Mato Grosso; com `--simular` só lê e conta. Pode rodar de novo: cada arquivo é apagado e inserido na mesma transação.
8. Transformação (Fase 2): `python src/05_transformacao.py` — roda os SQL de `src/sql/` em ordem (`raw` → `staging` → `analytics`), exporta cada tabela de `analytics` para `src/outputs/` e mostra as checagens de qualidade. O desenho está em [doc/arquitetura.md](doc/arquitetura.md).

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `doc/` | `estrategia.md` (Fase 1) e `arquitetura.md` (Fases 2 e 3) |
| `src/` | Scripts numerados na ordem de execução |
| `src/sql/` | SQL das camadas |
| `src/outputs/` | Tabelas finais que alimentam o dashboard |
| `src/dashboard/` | Arquivo do Power BI |
| `src/prompts/` | Conversas com IA usadas no projeto |

## Respostas

Recorte: Mato Grosso. Os números saem de `src/outputs/` e são refeitos por `python src/05_transformacao.py`.

| Pergunta | Resposta | Tabela em `src/outputs/` |
|---|---|---|
| P1 — Quanto da turma fica pelo caminho? | Turma de 2015, presencial (41.918 ingressantes): em 2024, de cada 100, 59,9 desistiram, 38,8 concluíram e 1,3 seguiam no curso. A maior perda é no 2º ano (2016): 16,7% da turma. | `p1_coorte_2015.csv` |
| P2 — Onde a rota mais se perde? | Desistência por área, por curso e ranking no 5º ano do curso, o último que as seis turmas alcançam. | `p2_desistencia_area.csv`, `p2_desistencia_curso.csv`, `p2_ranking_curso.csv` |
| P3 — Pública × privada, presencial × EAD | Evasão anual em 2024: privada EAD 33,9%, privada presencial 18,8%, pública EAD 5,3%, pública presencial 4,7%. Ano atípico: 2023 na rede pública (15,0% no presencial e 18,1% no EAD, contra 3 a 9% nos outros anos). | `p3_rede_modalidade.csv` |
| P4 — Qualidade retém? | Pouco: a correlação entre CPC e desistência é fraca (−0,10, em 497 cursos). A rede separa mais os cursos (privada 61,7% × pública 34,3%) do que a faixa do CPC. | `p4_curso.csv`, `p4_fatores.csv`, `p4_correlacao.csv` |
| P5 — O funil das licenciaturas | Turmas de 2015 a 2020: de cada 100, 53,6 desistiram, 31,6 concluíram e 14,8 seguiam em 2024. No Enade 2025, 54,7% dos concluintes participantes atingiram o padrão de proficiência. | `p5_funil_turma.csv`, `p5_enade_area.csv`, `p5_funil_resumo.csv`, `p5_curso.csv` |
| B1 — Desertos de ensino superior | Em 2024, MT tem 82.215 vagas presenciais para 397.671 jovens de 18 a 24 anos: 20,7 vagas por 100 jovens. Dos 141 municípios, 101 não têm nenhuma vaga presencial; neles moram 90.017 jovens (22,6% do estado). Os maiores sem oferta são Sapezal, Peixoto de Azevedo e Poconé. | `b1_vagas_por_jovens.csv` |
| B2 — Financiamento e permanência | Na rede privada, o FIES caiu de 3,3% das matrículas em 2021 para 1,4% em 2024, e o ProUni de 5,2% para 3,4%. Cursos com mais de 10% de alunos financiados têm evasão anual de 21,3%, contra 28,0% nos cursos sem financiados; a correlação é fraca (−0,07), então é associação, não causa. | `b2_financiamento_ano.csv`, `b2_financiamento_evasao.csv` |

Os bônus B1 e B2 são calculados por `python src/08_bonus.py`, direto dos arquivos do Censo 2021–2024 e do IBGE (tabela 9514, Censo 2022); por falta de tempo, não passam pelas camadas do banco.

Cobertura: a P4 usa os 497 cursos que têm CPC numérico e 10 ingressantes ou mais; a P5 cruza curso a curso apenas onde há 10 participantes ou mais no Enade.
