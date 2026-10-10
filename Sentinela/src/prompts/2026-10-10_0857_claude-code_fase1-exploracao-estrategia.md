# Sessão: leitura do desafio, exploração das bases e estratégia

- Data e hora: 10/10/2026, 08:57 a 12:17
- Ferramenta: Claude Code (Opus 5.5)
- Quem usou: Cleverson
- Fase: 1 (exploração e estratégia), com consultas de acompanhamento na Fase 2
- Conversa completa exportada: (colar aqui o nome do arquivo exportado ou o link)

## Prompts, na ordem

1. > analise o DataHack_Abertura_Rota_do_Diploma
2. > o que faz peder ponto ?
3. > Me ajude a montar a primeira faze
4. > pode exercutar
5. > arrume isso (depois de colar o erro do git pull)
6. > deu errado
7. > python instaldo e dados tambem no projeto
8. > com base no repositório o que da fase 1 já foi respondida e o que ainda falta
9. > feche o 1 e 2
10. > quais são os nomes das tabelas do banco
11. > o que falta fazer ?

## Decisões da equipe (a IA perguntou, nós escolhemos)

| Decisão       | O que a IA recomendou               | O que escolhemos                                                 | Por quê                                                                 |
| ------------- | ----------------------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Banco         | DuckDB (lê CSV e xlsx sem servidor) | PostgreSQL                                                       | A equipe domina; COPY, schemas para as camadas e transação para a carga |
| Dashboard     | Não recomendou                      | Power BI lendo os CSV de `src/outputs/`                          | Abre no pitch sem o banco local                                         |
| Papel da IA   | Criar os arquivos                   | Primeiro só o roteiro; depois autorizamos executar               | Entender o plano antes de aceitar código                                |
| Commit e push | —                                   | Feitos por nós; só o commit deste registro foi pela IA, a pedido | Controle do que entra no repositório                                    |

## O que a IA fez

1. Leu os 17 slides e as anotações do apresentador do .pptx.
2. Listou penalidades, desclassificação e o peso de cada critério na nota final.
3. Perfilou os CSV do Censo (linhas, colunas, chave, recorte de MT).
4. Escreveu os scripts `01`, `02`, `03` e `03b` de exploração e rodou todos.
5. Mediu as taxas de junção entre Trajetória, Censo, CPC e Enade.
6. Escreveu `doc/estrategia.md`, o README, o `.env.example`, o
   `requirements.txt`, o `00_schemas.sql` e o índice de prompts.
7. Incluiu `Dados/` no `.gitignore`.

## Aproveitado

- Achado de que a linha do Censo é curso × município, e não curso × ano como
  diz o slide 6: em MT 2024, 18.315 linhas para 3.890 cursos.
- Achado de que, no curso a distância, as vagas ficam numa linha sem estado
  e as matrículas nas linhas por município.
- Taxas de junção: 91,5% com o Censo, 67,3% com o CPC, 58,1% nas licenciaturas.
- Conferência de que permanência + conclusão + desistência fecha 100.
- Tabela de tipos e de vazios por coluna, com o tratamento de cada caso.
- `Dados/` fora do Git: a pasta não estava ignorada e o `git add` tentaria
  subir um CSV de 453 MB.

## Erros da IA que foram corrigidos

- **Limite que escondia dado:** a primeira versão do script `03b` classificava
  como "texto" a coluna com menos de 90% de números. Isso escondeu os 24 cursos
  "sem conceito" (SC) do CPC 2022. Foi descoberto ao comparar com a contagem
  direta na planilha; o limite foi corrigido e o script rodado de novo.
- **Afirmação sem prova:** a IA escreveu que os 6 cursos sem percentual no
  Enade eram "os mesmos" 6 com faixa SC. Só as quantidades tinham sido
  medidas; o texto foi reescrito.
- **Caminho quebrado:** o script `01` parou de achar os CSV quando os dados
  foram para subpastas. Corrigido para procurar nas subpastas.
- **Instrução incompleta de commit:** seguimos `commit` e `push` sem o
  `git add` e nada foi enviado. A IA leu o terminal e apontou o passo faltante.
- **Script entregue sem teste:** o primeiro script foi escrito sem Python na
  máquina. Só foi considerado válido depois de instalar e rodar.

## Inconsistências do material que a IA apontou

- Horário das entregas: slide 3 diz 10:45 e 14:15; slide 10 diz 11:00 e 15:00.
- A penalidade de −5 por linguagem causal só aparece nas anotações do slide 16.

## O que a IA não fez nesta sessão

### Ambiente

- Não criou o repositório no GitHub nem convidou os integrantes.
- Não instalou o Python nem o PostgreSQL; apontou que o Python faltava
- Não criou o arquivo `.env` nem digitou usuário ou senha do banco.
- Até o registro desta sessão, não fez commit nem push; só passou os comandos.
  O commit deste arquivo foi feito pela IA, a pedido.

### Banco de dados

- Não criou o banco `sentinela`.
- Não criou os schemas `raw`, `staging` e `analytics`: escreveu o arquivo
  `src/sql/00_schemas.sql`, mas não rodou.
- Não criou nenhuma tabela e não executou nenhum comando no banco, nem de
  leitura. Toda a exploração desta sessão foi feita direto nos arquivos
  (CSV, xlsx e JSON).
- Não carregou dado nenhum: o script `04_carga_raw.py` não é desta sessão.

### Transformação e respostas

- Não escreveu os SQL de `staging` (`10`, `11`, `12`), os de `analytics`
  (`20` a `24`) nem o de checagens (`90`).
- Não escreveu o `05_transformacao.py`.
- Não calculou a resposta de nenhuma pergunta (P1 a P5) e não gerou os CSV
  `p1_` a `p5_` de `src/outputs/`.
- Não conferiu se os números das respostas estão corretos.

### Documentos e dados

- Não baixou as bases (sessão registrada em
  `2026-10-10_0945_claude-code_download-bases.md`).
- Não escreveu `doc/arquitetura.md`, `doc/entrega1.md` nem
  `doc/micropitch1.md`.
- Não montou nada do dashboard.

## Não verificado (a conferir por nós)

- Que o número de ingressantes se repete em todas as linhas do curso na
  Trajetória: foi visto em uma amostra, não medido em todos os cursos.
- O motivo de não haver curso a distância no recorte de MT da Trajetória.
- Os nomes das 20 tabelas foram lidos dos scripts SQL e do registro de carga,
  não de uma consulta ao banco.
- O número de linhas de cada tabela `raw` foi tirado do
  `carga_raw_contagem.csv`, não contado no banco.
