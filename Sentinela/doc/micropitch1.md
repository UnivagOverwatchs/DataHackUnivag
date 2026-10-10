# Micro-pitch 1 — roteiro

3 minutos de fala + 2 de perguntas, na mesa da equipe. Apoio visual: [entrega1.md](entrega1.md).

## Fala (3 min)

**Abertura — 20 s**

Somos a equipe Sentinela. A pergunta do desafio é: de cada 100 que entram numa graduação em Mato Grosso, quantos chegam ao diploma. Na Fase 1 baixamos as quatro fontes, medimos cada uma e decidimos como carregar.

**Ambiente — 30 s**

O repositório é público e os quatro integrantes são colaboradores. Os dados ficam fora do Git. A stack é PostgreSQL, Python e Power BI. Escolhemos o PostgreSQL porque a equipe domina, porque o `COPY` carrega o arquivo de 453 MB de uma vez e porque os schemas separam as camadas. O banco fica num servidor único, para todos trabalharem na mesma base.

**O que os dados mostraram — 1 min 10 s**

Não confiamos no nome dos arquivos: medimos. Três achados mudaram o plano.

Primeiro: o Censo de cursos não é uma linha por curso. É uma linha por curso e por município. Em 2024, Mato Grosso tem 18 mil linhas para 3.890 cursos. Quem juntar direto com a Trajetória multiplica os números.

Segundo: na Trajetória, o total de ingressantes se repete em todos os anos do curso. Somar sem escolher um ano infla a turma em até dez vezes.

Terceiro: a vaga do curso a distância não tem município. Por isso o bônus dos desertos de ensino superior vai usar só vaga presencial.

E medimos as junções: 91,5% dos cursos da Trajetória têm par no Censo, 67,3% têm CPC e 58% das licenciaturas têm Enade. Vamos dizer essa cobertura em cada resposta.

**Estratégia — 45 s**

Três camadas. `raw` é a cópia fiel, tudo como texto, com o arquivo de origem. `staging` corrige os tipos, deixa só Mato Grosso e iguala os nomes das colunas entre os anos, porque o layout muda de 200 para 223 colunas. `analytics` tem uma tabela por pergunta.

A carga é idempotente: cada arquivo entra numa transação que apaga e insere de novo, então rodar duas vezes dá a mesma contagem.

Códigos sempre como texto, e nenhuma tabela mostra célula com menos de 10 alunos.

**Fecho — 15 s**

Na Fase 2 carregamos tudo por código, respondemos P1 e P2, que saem só da Trajetória, e trazemos o protótipo do dashboard.

## Perguntas prováveis

| Pergunta | Resposta |
|---|---|
| Por que não DuckDB? | Leria os CSV sem servidor, e consideramos. Ficamos com o PostgreSQL pelo domínio da equipe, pelos schemas e pela transação na carga. |
| Como garantem que rodar duas vezes não duplica? | Cada arquivo é apagado e inserido de novo na mesma transação; gravamos a contagem de linhas antes e depois da segunda execução. |
| Como chegaram na taxa de junção? | Script `src/03_exploracao_trajetoria.py`: parte dos 784 cursos de MT da Trajetória e conta quantos têm o mesmo código em cada base. Resultado em `src/outputs/exploracao_juncoes.csv`. |
| Por que o CPC cobre só 67%? | Cada edição avalia um grupo de áreas; nenhuma passa de 30% sozinha. Juntando 2021 a 2023 chega a 528 cursos. A P4 responde sobre esses. |
| O que fazem com curso sem par no Censo? | Continua na análise de trajetória, marcado como "sem dado de oferta". |
| E o EAD na P1 e na P2? | No recorte de MT, a Trajetória só tem curso presencial nas seis turmas. O EAD entra na P3, pelo Censo. |
| Por que a turma de 2020 é menor? | 28.985 ingressantes contra 42 a 45 mil. É ano atípico; comparamos as turmas pelo mesmo ano do curso e tratamos 2020 à parte. |
| O dashboard abre fora do laboratório? | Sim: o Power BI lê os CSV de `src/outputs/`, não o banco. E levamos PDF como plano B. |
| Como usaram IA? | As conversas estão em `src/prompts/`, com índice dizendo o que foi aproveitado e o que foi corrigido. |
