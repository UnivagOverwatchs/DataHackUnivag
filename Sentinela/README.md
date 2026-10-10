# Sentinela — Rota do Diploma

DataHack Univag 2026. De cada 100 que entram numa graduação em Mato Grosso, quantos chegam ao diploma, e em quais cursos a rota se perde?

## Stack

PostgreSQL 18 · Python (pandas, openpyxl, psycopg) · Power BI. A justificativa está em [doc/estrategia.md](doc/estrategia.md).

## Como rodar do zero

1. Instalar Python 3 e PostgreSQL.
2. `pip install -r requirements.txt`
3. Copiar `.env.example` para `.env` e preencher o acesso ao banco.
4. Baixar as bases para `Dados/` (a pasta não vai para o Git):
   - Censo da Educação Superior (INEP), 2021 a 2024
   - Indicadores de Trajetória (INEP), coortes 2015 a 2020
   - CPC 2021–2023, Conceito Enade 2025 e IGC (INEP)
   - Tabela 9514 do IBGE (SIDRA)
5. Criar as camadas: rodar `src/sql/00_schemas.sql` no banco.
6. Exploração: `python src/01_exploracao_censo.py`

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

| Pergunta | Onde está |
|---|---|
| P1 a P5, B1 | A preencher nas Fases 2 e 3 |
