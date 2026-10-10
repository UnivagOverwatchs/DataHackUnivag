# Entrega 1 — Ambiente, exploração e estratégia

Equipe Sentinela · DataHack Univag 2026 · Rota do Diploma · 10/10/2026

Detalhes e todas as tabelas: [estrategia.md](estrategia.md). Números reproduzíveis pelos scripts `src/01` a `src/03`; resultados em `src/outputs/`.

## 1. Ambiente

- **Repositório:** público, com os 4 integrantes como colaboradores. `Dados/` fica fora do Git; o README diz em que pasta cada base entra.
- **Stack:** PostgreSQL 18 · Python (pandas, openpyxl, psycopg) · Power BI.
- **Banco:** PostgreSQL em servidor único (VPS), para os quatro integrantes acessarem a mesma base. Acesso por `.env`, que não vai para o Git.
- **Por que PostgreSQL:** a equipe domina; `COPY` carrega o CSV de 453 MB sem passar linha a linha; schemas separam as camadas; transação dá carga segura. Alternativa considerada: DuckDB.

## 2. O que a exploração mostrou

| Fonte | Formato | Volume em MT | Chave |
|---|---|---|---|
| Trajetória (INEP) | 6 planilhas `.xlsx`, cabeçalho na linha 9 | 784 cursos, turmas de 2015 a 2020 | `CO_CURSO` + ano de ingresso + ano de referência |
| Censo — cursos (INEP) | CSV `;` latin-1, 258 a 453 MB | 18.315 linhas e 3.890 cursos em 2024 | `CO_CURSO` + município + ano |
| Censo — instituições (INEP) | CSV `;` latin-1, 1 MB | 74 com sede em MT em 2024 | `CO_IES` + ano |
| CPC, Enade, IDD, IGC (INEP) | `.xlsx`, uma por ano | recorte por `Sigla da UF` | `Código do Curso` / `Código da IES` |
| Tabela 9514 (IBGE) | JSON aninhado, 2,4 MB | 141 municípios | código do município, 7 dígitos |

Cinco achados que mudam a forma de trabalhar:

1. **A linha do Censo de cursos é curso × município × ano**, não curso × ano. Em 2024, 14.425 das 18.315 linhas de MT repetem um curso já visto. É preciso agregar antes de juntar.
2. **Na Trajetória, o número de ingressantes se repete em todos os anos do curso.** Somar sem escolher um ano multiplica a turma por até 10.
3. **A vaga do curso a distância não tem município.** Por isso o bônus B1 usa só vagas presenciais.
4. **O layout do Censo muda:** 200 colunas até 2022, 202 em 2023, 223 em 2024. A carga é pelo nome da coluna, nunca pela posição.
5. **A turma de 2020 é atípica:** 28.985 ingressantes, contra 42 a 45 mil nas anteriores.

Taxa de junção medida, partindo dos 784 cursos de MT da Trajetória:

| Junção | Cursos com par | Taxa |
|---|---|---|
| Trajetória × Censo 2021–2024 | 717 | 91,5% |
| Trajetória × CPC 2021–2023 | 528 | 67,3% |
| Licenciaturas × Enade Licenciaturas | 75 de 129 | 58,1% |

A P4 e a P5 serão apresentadas com essa cobertura declarada.

## 3. Estratégia

- **Três camadas:** `raw` (cópia fiel, tudo texto, com arquivo de origem e data da carga) → `staging` (tipos corrigidos, só MT, nomes iguais entre os anos) → `analytics` (uma tabela por pergunta, exportada para `src/outputs/`).
- **Idempotência:** em `raw`, cada arquivo é recarregado numa transação que apaga e insere as linhas daquele arquivo; `staging` e `analytics` são recriadas do zero. Rodar duas vezes dá a mesma contagem, e a contagem fica gravada.
- **Junções:** todos os códigos como texto; Censo agregado para curso × ano antes de juntar; taxa de junção medida e informada em cada resposta.
- **Sigilo:** nenhuma tabela ou gráfico mostra célula com menos de 10 alunos.
- **Dashboard fora do laboratório:** o Power BI lê os CSV de `src/outputs/`, sem depender do banco; plano B em PDF.

## 4. Próximo passo (Fase 2)

Carga por código das quatro fontes em `raw`, transformação para `staging`, primeiras respostas (P1 e P2 saem só da Trajetória) e protótipo do dashboard.
