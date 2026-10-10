# Micro-pitch 2 — roteiro

Fase 2 · ingestão, transformação e protótipo · 3 minutos de fala + 2 de perguntas, na mesa da equipe.

## Fala (3 min)

**1. Arquitetura (40 s)** — abrir `doc/arquitetura.md` no diagrama.

- O dado anda em linha reta: arquivo → `raw` → `staging` → `analytics` → CSV → dashboard.
- É ELT: o Python só extrai e carrega; toda a transformação é SQL dentro do PostgreSQL.
- `raw` guarda tudo como texto, sem corrigir nada. `staging` corrige tipos e nomes. `analytics` tem uma tabela por pergunta.

**2. Ingestão e idempotência (40 s)** — abrir `src/outputs/carga_raw_contagem.csv`.

- Quatro fontes carregadas por código: Trajetória, Censo de cursos, CPC e Enade Licenciaturas.
- Cada arquivo roda em uma transação que apaga as linhas daquele arquivo e insere de novo.
- Prova: a segunda execução encontrou 89.842 linhas no banco e terminou com 89.842.

**3. Transformação e qualidade (50 s)** — abrir `src/outputs/checagens.csv`.

- O Censo vem em curso × município; agregamos para curso × ano antes de qualquer junção.
- Comparamos turmas pelo "ano do curso", não pelo ano civil. O ranking usa o 5º ano, o último que as seis turmas alcançam.
- "Sem conceito" do CPC vira nulo em vez de quebrar a conta.
- 18 checagens automáticas, todas passando. Três exemplos: permanência + conclusão + desistência fecha 100; a desistência acumulada que calculamos bate com a do INEP; nenhuma tabela publicada tem contagem abaixo de 10 alunos.

**4. Primeiras respostas e protótipo (50 s)** — abrir `src/dashboard/prototipo.html`.

- P1: da turma de 2015 no presencial, de cada 100, 59,9 desistiram e 38,8 concluíram até 2024. A maior perda é no 2º ano.
- P3: em 2024 a evasão anual vai de 4,7% na pública presencial a 33,9% na privada a distância.
- P4: a nota do CPC tem associação fraca com a desistência (−0,10); a rede separa mais os cursos.
- Passar pelas cinco abas: cada uma abre com a resposta em uma frase.

## Perguntas prováveis

| Pergunta | Resposta |
|---|---|
| Por que `raw` só tem Mato Grosso? | Tempo e espaço: o Censo completo passa de 1 GB. O script aceita carregar o Brasil inteiro; rodamos com a opção de MT. O filtro é pelo código da UF, sem outra transformação. |
| E as outras bases (IES, IGC, IDD, IBGE)? | Estão baixadas e exploradas. Não entraram porque as cinco perguntas obrigatórias não precisam delas. O IBGE entra na Fase 3, para o bônus B1. |
| Qual a taxa de junção? | Trajetória com Censo 2021–2024: 91,5% (717 de 784 cursos). Com o CPC: 67,3%, porque cada edição avalia só um grupo de áreas. Na P4 entram 497 cursos com nota numérica e 10 ingressantes ou mais. |
| Como sabem que não duplicou? | A contagem antes e depois de cada carga fica gravada, e a checagem compara `raw` com `staging`. |
| Por que 2023 aparece como atípico na rede pública? | A evasão foi de 15,0% no presencial e 18,1% no EAD, contra 3% a 9% nos outros anos. Marcamos como atípico pela regra do dobro da mediana; a causa não está nos dados e não afirmamos uma. |
| O protótipo é HTML e a estratégia diz Power BI? | O HTML lê os mesmos CSV que o Power BI vai ler e abre de qualquer computador. Serve de protótipo agora e de plano B no pitch final. |
| O que é do aluno e o que é da IA? | Está em `src/prompts/`: decisões nossas, o que foi aproveitado e os erros da IA que corrigimos. |

## Antes de a banca chegar

- Abrir em abas: `arquitetura.md`, `carga_raw_contagem.csv`, `checagens.csv` e `prototipo.html`.
- Conferir que o último commit está no GitHub.
- Definir quem fala cada um dos quatro blocos.
