# Estratégia de ingestão e transformação — Fase 1

Equipe Sentinela · DataHack Univag 2026 · desafio Rota do Diploma

## 1. Stack e por quê

| Camada | Escolha | Motivo |
|---|---|---|
| Banco | PostgreSQL 18 | A equipe domina; `COPY` carrega o CSV de 450 MB sem passar linha a linha; schemas separam as camadas; transação garante carga segura. |
| Linguagem | Python (pandas, openpyxl, psycopg) | Lê no mesmo código o xlsx com cabeçalho deslocado, o CSV em latin-1 e o JSON do IBGE. |
| Dashboard | Power BI | Lê os CSV de `src/outputs/`, então abre no pitch sem depender do banco local. |

Alternativa considerada: DuckDB leria os CSV sem servidor. Ficamos com o PostgreSQL pelo domínio da equipe e pelo uso de schemas e transações.

## 2. O que encontramos nas fontes

### Censo da Educação Superior — cursos

Arquivo CSV, separador `;`, codificação latin-1, sem BOM, todas as linhas com o mesmo número de colunas.

| Ano | Tamanho | Colunas | Linhas (Brasil) | Linhas MT | Cursos distintos MT | Municípios MT | IES em MT |
|---|---|---|---|---|---|---|---|
| 2016 | 54 MB | 200 | 92.866 | 2.529 | 1.057 | 52 | 79 |
| 2020 | 200 MB | 200 | 344.691 | 9.773 | 2.404 | 92 | 142 |
| 2021 | 258 MB | 200 | 444.786 | 12.278 | 2.737 | 94 | 157 |
| 2024 | 453 MB | 223 | 720.349 | 18.315 | 3.890 | 104 | 170 |

MT = `CO_UF = 51`. O layout muda: 200 colunas até 2021 e 223 em 2024, então a carga não pode depender da posição da coluna, só do nome.

### Censo da Educação Superior — instituições

| Ano | Linhas | IES com sede em MT | `CO_IES` repetido |
|---|---|---|---|
| 2016 | 2.407 | 59 | 0 |
| 2020 | 2.457 | 64 | 0 |
| 2021 | 2.574 | 69 | 0 |
| 2024 | 2.561 | 74 | 0 |

Uma linha por instituição por ano; a chave é `CO_IES` + `NU_ANO_CENSO`. O nome do arquivo muda em 2024 (`MICRODADOS_ED_SUP_IES_2024`), e as colunas de local têm sufixo `_IES` (`CO_UF_IES`, `CO_MUNICIPIO_IES`).

### Achados que mudam a estratégia

1. **A linha do Censo de cursos não é "curso × ano".** É curso × município × ano. Em MT 2024, 18.315 linhas representam 3.890 cursos: 14.425 linhas repetem um `CO_CURSO` já visto. Juntar com a Trajetória por `CO_CURSO` sem agregar antes multiplica os números.
2. **O curso a distância aparece de dois jeitos.** No arquivo de 2024, cada curso EAD tem linhas por município do polo (com as matrículas e sem vagas) e uma linha sem estado nem município (com as vagas e quase sem matrículas). No Brasil: 18.590.273 vagas estão nas linhas sem estado e 0 nas linhas com estado; 5.186.811 matrículas estão nas linhas com estado e 2.580 nas sem estado.
3. **Consequência para as perguntas.** Matrícula e ingresso EAD de MT saem das linhas com `CO_UF = 51`. Vaga EAD não tem município, por isso o bônus B1 usa só vagas presenciais.
4. **Quase todas as linhas de MT são EAD e privadas.** Em 2024: 17.489 linhas EAD contra 826 presenciais; 17.783 da rede privada contra 532 da pública. Contar linhas não mede oferta; a medida é a soma de `QT_MAT`, `QT_ING` e `QT_VG_TOTAL`.
5. **A IES que oferta em MT nem sempre tem sede em MT.** Em 2024, 170 instituições têm curso em MT e só 74 têm sede no estado. O recorte de MT é feito pelo curso, não pela sede da instituição.

### Pendências de fonte

- Faltam os Censos de 2022 e 2023 (a P3 pede 2021 a 2024). Os de 2016 e 2020 já baixados não entram nas perguntas.
- Faltam baixar: Indicadores de Trajetória (coortes 2015 a 2020), CPC 2021–2023, Conceito Enade 2025, IGC e a tabela 9514 do IBGE.
- A explorar na Trajetória: cabeçalho na linha 9; uma linha por curso e por ano de acompanhamento; conferir se permanência + conclusão + desistência (`TAP + TCA + TDA`) fecha 100.

## 3. Camadas no banco

| Schema | Conteúdo | Regra |
|---|---|---|
| `raw` | Cópia fiel de cada arquivo | Todas as colunas como texto, mais `arquivo_origem` e `carregado_em`. Nada é corrigido aqui. |
| `staging` | Dado limpo | Tipos corrigidos, códigos como texto, só MT, nomes de coluna iguais entre os anos. |
| `analytics` | Uma tabela por pergunta (P1 a P5, B1) | Já agregada, com a regra de sigilo aplicada. Exportada para `src/outputs/`. |

## 4. Idempotência

- `raw`: cada arquivo é carregado em uma transação que apaga as linhas daquele `arquivo_origem` e insere de novo. Rodar duas vezes dá a mesma contagem.
- `staging` e `analytics`: recriadas do zero a cada execução.
- Checagem: contagem de linhas por arquivo antes e depois da segunda execução, gravada em `src/outputs/`.

## 5. Junções

| Junção | Chave | Cuidado |
|---|---|---|
| Trajetória × Censo cursos | `CO_CURSO` | Agregar o Censo para curso × ano antes de juntar. |
| Trajetória × CPC / Enade | `CO_CURSO` | Só parte dos cursos é avaliada em cada ciclo; informar quantos entraram. |
| Censo cursos × Censo IES | `CO_IES` + ano | Local da oferta vem do curso, não da IES. |
| Censo IES × IGC | `CO_IES` | — |
| Censo cursos × IBGE | `CO_MUNICIPIO` (7 dígitos) | Só linhas presenciais têm vaga por município. |

Todos os códigos são lidos como texto. A taxa de junção de cada linha da tabela será medida na Fase 2 e registrada aqui.

## 6. Qualidade e regras de leitura

- Não exibir curso ou célula com menos de 10 alunos.
- Os dados são agregados: escrever "está associado a", nunca "causa".
- Toda resposta leva o número, a base e o filtro usado.

## 7. Riscos

| Risco | Como tratamos |
|---|---|
| CSV de 2024 com 453 MB | Carga por `COPY`; leitura em Python por blocos. |
| Layout diferente entre anos | Carga pelo nome da coluna; colunas ausentes ficam nulas. |
| Dados no Git | `Dados/` no `.gitignore`; o README diz de onde baixar. |
| Dashboard fora do laboratório | Power BI lê `src/outputs/`; plano B em PDF com prints. |
