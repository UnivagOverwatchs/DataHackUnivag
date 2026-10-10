# Sessão: download das bases por órgão

- Data e hora: 10/10/2026, 09:45 a 10:00
- Ferramenta: Claude Code (Opus 5.5)
- Quem usou: Cleverson
- Fase: 1 (exploração e estratégia)

## Prompt

> pegue as bases de dados pedidas no DataHack_Abertura_Rota_do_Diploma e coloque no repositorio separe por orgão

### O que a IA fez

1. Leu o texto dos 17 slides do .pptx e achou as quatro fontes no slide 5.
2. Procurou os links nas páginas de dados abertos do INEP (o .pptx não traz links).
3. Baixou Trajetória (turmas 2015 a 2020), Censo 2022 e 2023, CPC, IDD, IGC e
   Conceito Enade 2021–2023, Enade Licenciaturas 2025 e a tabela 9514 do IBGE
   (população por idade dos 141 municípios de MT, Censo 2022).
4. Organizou em `Dados/INEP/{trajetoria, censo_superior, indicadores_qualidade}`
   e `Dados/IBGE/sidra`.
5. Conferiu o md5 das planilhas de Trajetória e dos CSV do Censo 2022 e 2023
   com o publicado pelo INEP: todos bateram.

### Aproveitado

- A estrutura de pastas por órgão e todos os arquivos baixados.

### Corrigido ou a conferir

- A IA moveu os CSV do Censo que já estavam em `Dados/` para a subpasta do INEP,
  e o script `01_exploracao_censo.py` deixou de achá-los. Corrigido no script,
  que passou a procurar os CSV também nas subpastas (`rglob`).
- Os CSV de 2016, 2020, 2021 e 2024 já estavam na pasta e não tiveram o md5
  conferido.
- O dicionário .xlsx do Censo não foi extraído: a IA apagou os zips antes de
  notar a falha.
- O slide cita "renda e outros" no IBGE sem dizer a tabela; só a 9514 foi baixada.
