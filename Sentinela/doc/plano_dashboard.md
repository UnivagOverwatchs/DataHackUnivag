# Plano do dashboard

Equipe Sentinela · Rota do Diploma · Entrega 2

## Para quem é

Gestores de ensino superior de Mato Grosso (secretarias, reitorias, coordenações de curso) e a banca de negócio. A pessoa precisa sair sabendo quanto se perde, onde se perde e o que acompanha a perda, sem precisar ler tabela.

## Como funciona

- Uma tela por pergunta. Cada tela abre com a resposta em uma frase, com número; os gráficos embaixo sustentam a frase.
- Lê a camada `analytics` pela API da equipe e, se ela não responder, pelos CSV de `src/outputs/`, que são a exportação da mesma camada.
- A página é gerada com os dados embutidos, então abre fora do laboratório, sem banco e sem internet.
- Dashboard: `src/dashboard/prototipo.html`, gerado por `python src/06_prototipo_dashboard.py --api <endereço da API>`.

## Telas

| Tela | Pergunta que responde | O que mostra | Tabela de origem |
|---|---|---|---|
| A turma | P1 — Quanto da turma fica pelo caminho? | Quatro números de destaque; barras empilhadas da turma de 2015 ano a ano (seguem, concluíram, desistiram); desistência em cada ano do curso | `p1_coorte_2015` |
| Onde se perde | P2 — Onde a rota mais se perde? | Desistência por área no 5º ano do curso; os 10 cursos com maior e com menor desistência | `p2_desistencia_area`, `p2_ranking_curso` |
| Rede e modalidade | P3 — Pública × privada, presencial × EAD | Evasão anual de 2021 a 2024 em linhas, com o ano atípico marcado; tabela de matrículas | `p3_rede_modalidade` |
| Qualidade | P4 — Qualidade retém? | Desistência por rede, faixa do CPC, grau e área; correlação de cada indicador com a desistência | `p4_fatores`, `p4_correlacao` |
| Licenciaturas | P5 — O funil das licenciaturas | Funil de cada 100 ingressantes; proficiência no Enade 2025 por área | `p5_funil_resumo`, `p5_enade_area` |

## Regras de leitura aplicadas

- Nenhum curso, área ou célula com menos de 10 alunos aparece.
- O texto fala em associação, nunca em causa: os dados são agregados por curso.
- Toda taxa diz sobre o que é calculada (quem entrou, quem tinha vínculo no ano, quem fez a prova).
- O último degrau do funil da P5 é marcado como estimativa.

## O que falta para o produto final (Fase 3)

| Item | Por quê |
|---|---|
| Tela do bônus (B1 ou B2) | Leva o critério "Respondeu às perguntas" ao nível mais alto |
| Filtro por rede e por área na tela "Onde se perde" | Hoje a tela soma as seis turmas; o gestor vai querer ver o próprio recorte |
| Corte mínimo maior no ranking de cursos | Cursos com poucas dezenas de ingressantes aparecem com 100% de desistência |
| Tela de recomendações | "Valor e recomendações" vale 20 pontos na rubrica de negócio |
| Versão em Power BI ou decisão de manter o HTML | A estratégia declara Power BI; a escolha final precisa estar justificada |
| Plano B em PDF | Prints das telas, exigido na entrega final |
