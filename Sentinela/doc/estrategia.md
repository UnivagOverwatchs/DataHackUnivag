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
| 2022 | 332 MB | 200 | 573.019 | 15.059 | 3.234 | 96 | 165 |
| 2023 | 393 MB | 202 | 671.610 | 17.022 | 3.631 | 93 | 168 |
| 2024 | 453 MB | 223 | 720.349 | 18.315 | 3.890 | 104 | 170 |

MT = `CO_UF = 51`. O layout muda: 200 colunas até 2022, 202 em 2023 e 223 em 2024, então a carga não pode depender da posição da coluna, só do nome. As perguntas usam 2021 a 2024; 2016 e 2020 ficam só como referência.

### Censo da Educação Superior — instituições

| Ano | Linhas | IES com sede em MT | `CO_IES` repetido |
|---|---|---|---|
| 2016 | 2.407 | 59 | 0 |
| 2020 | 2.457 | 64 | 0 |
| 2021 | 2.574 | 69 | 0 |
| 2022 | 2.595 | 72 | 0 |
| 2023 | 2.580 | 72 | 0 |
| 2024 | 2.561 | 74 | 0 |

Uma linha por instituição por ano; a chave é `CO_IES` + `NU_ANO_CENSO`. O nome do arquivo muda a partir de 2022 (`MICRODADOS_ED_SUP_IES_AAAA`), e as colunas de local têm sufixo `_IES` (`CO_UF_IES`, `CO_MUNICIPIO_IES`).

### Indicadores de Trajetória

Planilha `.xlsx`, uma por turma de ingresso, de 28 a 43 MB. O título ocupa as linhas 1 a 8; os nomes técnicos das colunas estão na linha 9 e os dados começam na linha 10. São 31 colunas.

| Turma | Linhas (Brasil) | Linhas MT | Cursos MT | IES MT | Municípios MT | Ingressantes MT | Cursos com menos de 10 ingressantes |
|---|---|---|---|---|---|---|---|
| 2015 | 281.431 | 5.150 | 515 | 47 | 30 | 41.918 | 15 |
| 2016 | 263.179 | 5.157 | 573 | 49 | 30 | 45.453 | 16 |
| 2017 | 247.201 | 4.864 | 608 | 51 | 33 | 44.959 | 30 |
| 2018 | 230.210 | 4.361 | 623 | 53 | 31 | 43.223 | 28 |
| 2019 | 206.809 | 3.876 | 646 | 60 | 34 | 41.881 | 36 |
| 2020 | 174.241 | 3.105 | 621 | 60 | 31 | 28.985 | 47 |

- Cada linha é curso × ano de ingresso × ano de referência. A chave `CO_CURSO` + `NU_ANO_INGRESSO` + `NU_ANO_REFERENCIA` não se repete em nenhum arquivo.
- `QT_INGRESSANTE` se repete em todas as linhas do curso: somar sem escolher um ano de referência multiplica a turma por até 10.
- Permanência + conclusão + desistência (`TAP + TCA + TDA`) fecha 100 em todas as linhas de MT; nenhuma taxa nula.
- No recorte de MT só há cursos presenciais (nenhum EAD nas seis turmas). A P1 e a P2 respondem sobre o presencial.
- A turma de 2020 tem 28.985 ingressantes contra cerca de 42 a 45 mil nas anteriores: ano atípico, a tratar à parte nas comparações.
- São 784 cursos distintos de MT somando as seis turmas.

### Indicadores de qualidade (CPC, Enade, IDD, IGC)

Planilhas `.xlsx` com cabeçalho na linha 1, uma por ano.

| Base | Linhas (Brasil) | Chave | Observação |
|---|---|---|---|
| CPC 2021 / 2022 / 2023 | 8.001 / 9.892 / 9.812 | `Código do Curso` | 40 colunas em 2021, 39 depois; a ordem das colunas muda. |
| Conceito Enade 2021 / 2022 / 2023 | 8.000 / 9.896 / 9.815 | `Código do Curso` | Em 2021 a primeira aba é um aviso; os dados estão na segunda. |
| Enade Licenciaturas (2025) | 4.951 | `Código do Curso` | Traz o percentual de concluintes no padrão de proficiência (P5). |
| IDD 2021 / 2022 / 2023 | 8.000 / 9.896 / 9.815 | `Código do Curso` | — |
| IGC 2021 / 2022 / 2023 | 2.014 / 2.023 / 2.101 | `Código da IES` | Uma linha por instituição; tem abas extras de apoio. |

Os nomes das colunas vêm com espaço no começo e asteriscos no fim (`' Código do Curso**'`), e mudam entre os anos. A carga limpa o nome antes de usar. O recorte de MT nessas planilhas é pela coluna `Sigla da UF`.

### IBGE — tabela 9514 (Censo 2022)

JSON da API de agregados, 2,4 MB, população residente por idade para os municípios de MT. O município vem em `localidade.id` com 7 dígitos, igual ao `CO_MUNICIPIO` do Censo. A estrutura é aninhada (variável → classificações → séries), então precisa ser achatada antes de carregar.

### Tipos e vazios por coluna

Medido no recorte de MT, coluna a coluna, pelo script `src/03b_exploracao_tipos_nulos.py`; o resultado completo está em `src/outputs/exploracao_tipos_nulos.csv`.

**Tipos.** Todos os arquivos chegam como texto. O tipo de destino na camada `staging` é:

| Grupo de colunas | Exemplos | Tipo no `staging` |
|---|---|---|
| Códigos | `CO_CURSO`, `CO_IES`, `CO_MUNICIPIO`, `CO_CINE_AREA_GERAL`, `Código do Curso` | Texto. `CO_CINE_AREA_GERAL` tem zero à esquerda (`04`), que se perderia como número. |
| Categorias codificadas | `TP_REDE`, `TP_MODALIDADE_ENSINO`, `TP_GRAU_ACADEMICO`, `TP_CATEGORIA_ADMINISTRATIVA` | Inteiro pequeno, com tabela de descrição. |
| Anos e prazos | `NU_ANO_CENSO`, `NU_ANO_INGRESSO`, `NU_ANO_REFERENCIA`, `NU_PRAZO_INTEGRALIZACAO` | Inteiro. |
| Quantidades | `QT_MAT`, `QT_ING`, `QT_VG_TOTAL`, `QT_SIT_DESVINCULADO`, `QT_ING_FIES`, `QT_INGRESSANTE`, `QT_DESISTENCIA` | Inteiro. |
| Taxas e notas | `TAP`, `TCA`, `TDA`, `TADA`, `CPC (Contínuo)`, percentual de proficiência do Enade | Decimal, com ponto como separador. As taxas da Trajetória vêm com até 9 casas (`98.97959184`). |
| Faixas de conceito | `CPC (Faixa)`, `IGC (Faixa)`, `Conceito Enade (Faixa)` | Inteiro de 1 a 5, com nulo para "sem conceito". |
| Nomes | `NO_CURSO`, `NO_IES`, `Área de Avaliação` | Texto. |

Nas planilhas de qualidade, categoria e modalidade vêm por extenso (`Pública Federal`, `Educação Presencial`), e não em código como no Censo e na Trajetória. A comparação entre as bases usa o código do curso, não esses textos.

**Vazios e valores fora do tipo.**

| Base | O que encontramos em MT | Como tratamos |
|---|---|---|
| Trajetória (6 turmas) | Nenhuma célula vazia nas 31 colunas. | Nada a tratar. |
| Censo cursos 2021–2024 | Nenhum vazio nas chaves nem nas quantidades. `TP_GRAU_ACADEMICO` vazio em 3 linhas (2021), 0 (2022), 30 (2023) e 38 (2024). | Linha mantida, grau como "não informado". |
| Censo cursos 2021–2024 | `CO_CINE_ROTULO` vem com aspas dentro do valor (`"0413A01"`) em 100% das linhas; na Trajetória vem sem aspas (`0421D01`). | Remover as aspas no `staging`. |
| CPC 2021 / 2022 / 2023 | `CPC (Faixa)` traz o texto `SC` (sem conceito) em 6 de 155, 24 de 165 e 11 de 238 cursos; nesses, `CPC (Contínuo)` está vazio. | `SC` vira nulo; o curso sai da P4 e a contagem é informada. |
| CPC 2021 / 2023 | Nota do IDD vazia em 17 (11,0%) e 22 (9,2%) cursos. | Só afeta análise do IDD, não a P4. |
| Enade Licenciaturas | Percentual de proficiência vazio em 6 de 97 cursos, e faixa `SC` também em 6; participantes vazio em 4. | Fora da P5, com a contagem informada. |
| IGC 2021–2023 | Faixa `SC` em 1 instituição (2023); conceitos de mestrado e doutorado vazios em quem não tem pós. | `SC` vira nulo; colunas de pós não são usadas. |
| Todas as planilhas de qualidade | `Sigla da IES` vazia em 8% a 22% das linhas. | Usar o nome ou o código da IES, nunca a sigla. |

Consequência para a cobertura: dos 558 cursos de MT com linha no CPC, parte está sem conceito em cada edição, então o número de cursos que entra na P4 é menor que os 528 com par na Trajetória. O valor exato sai na Fase 2, depois de descartar os `SC`.

### Achados que mudam a estratégia

1. **A linha do Censo de cursos não é "curso × ano".** É curso × município × ano. Em MT 2024, 18.315 linhas representam 3.890 cursos: 14.425 linhas repetem um `CO_CURSO` já visto. Juntar com a Trajetória por `CO_CURSO` sem agregar antes multiplica os números.
2. **O curso a distância aparece de dois jeitos.** No arquivo de 2024, cada curso EAD tem linhas por município do polo (com as matrículas e sem vagas) e uma linha sem estado nem município (com as vagas e quase sem matrículas). No Brasil: 18.590.273 vagas estão nas linhas sem estado e 0 nas linhas com estado; 5.186.811 matrículas estão nas linhas com estado e 2.580 nas sem estado.
3. **Consequência para as perguntas.** Matrícula e ingresso EAD de MT saem das linhas com `CO_UF = 51`. Vaga EAD não tem município, por isso o bônus B1 usa só vagas presenciais.
4. **Quase todas as linhas de MT são EAD e privadas.** Em 2024: 17.489 linhas EAD contra 826 presenciais; 17.783 da rede privada contra 532 da pública. Contar linhas não mede oferta; a medida é a soma de `QT_MAT`, `QT_ING` e `QT_VG_TOTAL`.
5. **A IES que oferta em MT nem sempre tem sede em MT.** Em 2024, 170 instituições têm curso em MT e só 74 têm sede no estado. O recorte de MT é feito pelo curso, não pela sede da instituição.

6. **O arquivo de 2022 não tem a linha EAD sem estado** (0 linhas, contra 7.948 em 2021 e 11.039 em 2023). A série de vagas EAD não é comparável nesse ano; a de matrículas é.

### Taxa de junção medida

Base de partida: os 784 cursos de MT que aparecem na Trajetória.

| Junção | Cursos com par | Taxa |
|---|---|---|
| Trajetória × Censo cursos 2021 | 715 de 784 | 91,2% |
| Trajetória × Censo cursos 2022 | 703 de 784 | 89,7% |
| Trajetória × Censo cursos 2023 | 677 de 784 | 86,4% |
| Trajetória × Censo cursos 2024 | 646 de 784 | 82,4% |
| Trajetória × Censo cursos 2021–2024 (qualquer ano) | 717 de 784 | 91,5% |
| Trajetória × CPC 2021 | 140 de 784 | 17,9% |
| Trajetória × CPC 2022 | 154 de 784 | 19,6% |
| Trajetória × CPC 2023 | 234 de 784 | 29,8% |
| Trajetória × CPC 2021–2023 (qualquer ano) | 528 de 784 | 67,3% |
| Licenciaturas da Trajetória × Enade Licenciaturas | 75 de 129 | 58,1% |

Leitura:

- A taxa com o Censo cai ano a ano porque cursos das turmas antigas deixam de existir. Curso sem par no Censo é mantido na análise de trajetória e marcado como "sem dado de oferta".
- Cada edição do CPC avalia só um grupo de áreas, por isso nenhuma passa de 30%. Juntando as três edições chega a 67,3%. A P4 vai informar que responde sobre 528 cursos, e não sobre todos.
- Na P5, 75 das 129 licenciaturas da Trajetória têm resultado no Enade Licenciaturas; o resultado será apresentado com essa cobertura.

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

Todos os códigos são lidos como texto. As taxas medidas estão na seção 2; os números saem de `src/03_exploracao_trajetoria.py` e ficam em `src/outputs/exploracao_juncoes.csv`.

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
