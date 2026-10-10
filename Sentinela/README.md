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
