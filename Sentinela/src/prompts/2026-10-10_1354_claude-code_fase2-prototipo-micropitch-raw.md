# Sessão: protótipo do dashboard, micro-pitch 2 e fechamento da camada raw

- Data e hora: 10/10/2026, 13:54 a 14:40
- Ferramenta: Claude Code (Opus 5.5)
- Quem usou: Cleverson
- Fase: 2 (ingestão, transformação e protótipo)
- Continuação da sessão registrada em `2026-10-10_0857_claude-code_fase1-exploracao-estrategia.md`
- Conversa completa exportada: (colar aqui o nome do arquivo exportado ou o link)

## Prompts, na ordem

1. > na fase 2 , o que falta
2. > pode iniciar o protitipo
3. > da fase todos aonde estamos e o que falta ? (com o print do slide da Fase 2)
4. > a proxima apresentação e comeca as 15:30
5. > esse foi nosso primeiro petch (com o PDF do micro-pitch 1)
6. > Você já finalizou camada raw ?
7. > preciso que finalize o ran
8. > o que falta ainda fazer
9. > foque na fase 2 , vamos finalizar elea

## Decisões da equipe

| Decisão | O que a IA propôs | O que ficou | Por quê |
|---|---|---|---|
| Formato do protótipo | HTML de uma página, porque a IA não gera arquivo do Power BI | Aceito como protótipo | Lê os mesmos CSV de `src/outputs/` e abre sem banco |
| Estilo do micro-pitch 2 | Roteiro em texto | Slides no mesmo visual do micro-pitch 1, que mostramos à IA | Manter a identidade da equipe entre as apresentações |
| Carga no banco | — | Rodada por nós, não pela IA | A IA só simulou a leitura; quem grava no banco somos nós |
| Bônus | Começar pelo B2 | Adiado: primeiro fechar a Fase 2 | Prioridade no que é avaliado às 15:30 |

## O que a IA fez

1. Comparou o repositório com os quatro itens do slide da Fase 2 e com os cinco critérios da rubrica.
2. Escreveu `src/06_prototipo_dashboard.py` e o modelo HTML; gerou `src/dashboard/prototipo.html`
   com cinco abas, uma por pergunta, a partir dos CSV de `src/outputs/`.
3. Escreveu `doc/plano_dashboard.md` e `doc/micropitch2.md` (fala e perguntas prováveis).
4. Leu o PDF do micro-pitch 1, copiou o visual e gerou `doc/micropitch2_slides.html` e `doc/micropitch2.pdf`.
5. Acrescentou cinco fontes ao `src/04_carga_raw.py`: Censo de instituições, IGC, IDD,
   Conceito Enade 2021–2023 e a população por idade do IBGE (leitor novo para o JSON aninhado).
6. Acrescentou três checagens de taxa de junção ao `src/sql/90_checagens.sql`.
7. Ajustou `doc/estrategia.md` e `doc/arquitetura.md` para dizer o que foi de fato executado.

## Aproveitado

- Protótipo com a resposta em uma frase no topo de cada tela.
- Slides do micro-pitch 2, com a prova de idempotência (0 → 89.842 e 89.842 → 89.842).
- Leitor do JSON do IBGE: 141 municípios × 134 combinações de sexo e idade = 18.894 linhas.
- Simulação da carga nova: os totais de MT bateram com a exploração
  (instituições 69/72/72/74; IGC 45/45/51; cursos avaliados 155/165/238).

## Erros e inconsistências apontados e corrigidos

- **Documento diferente da execução:** a estratégia dizia que `raw` é cópia fiel e que o filtro
  de MT acontece no `staging`, mas a carga rodou filtrando MT na entrada. O texto foi corrigido
  para dizer o que foi feito e por quê.
- **Taxa de junção fora do pipeline:** tinha sido medida só na exploração. Entrou como checagem.
- **Texto do protótipo:** a frase da P3 saía com "ead" em minúsculas; corrigido no modelo.
- **Cartões desalinhados** nos slides do micro-pitch 2; corrigido antes de gerar o PDF.
- **Arquitetura citava só Power BI:** passou a citar o protótipo em HTML e o script que o gera.

## O que a IA não fez nesta sessão

- Não rodou a carga nem a transformação no banco: só o modo de simulação, que lê e conta.
- Não fez commit nem push.
- Não montou painel no Power BI.
- Não escreveu `staging` nem `analytics` para as cinco fontes novas.
- Não respondeu os bônus B1 e B2.

## Não verificado (a conferir por nós)

- As três checagens de junção esperam 717, 528 e 75 cursos, medidos nos arquivos. Só depois de
  rodar `05_transformacao.py` saberemos se o banco dá os mesmos números.
- No protótipo, a IA só viu a tela da P1; as outras quatro foram conferidas pelo conteúdo.
- A "maior dificuldade" do slide 2 do micro-pitch 2 foi sugestão da IA.
- No ranking da P2 aparecem cursos com 100% de desistência e cerca de 20 a 30 ingressantes.
