-- P1 - Quanto da turma fica pelo caminho?
-- Turma de 2015, presencial, MT: de cada 100 que entraram, quantos desistiram, concluíram
-- e seguiam no curso em cada ano até 2024, e em que ano a perda foi maior.
-- Os percentuais são sobre quem entrou; as quatro situações somam 100.
-- Sigilo: contagem abaixo de 10 alunos sai vazia, junto com o seu percentual.
DROP TABLE IF EXISTS analytics.p1_coorte_2015;

CREATE TABLE analytics.p1_coorte_2015 AS
WITH por_ano AS (
    SELECT ano_referencia,
           ano_do_curso,
           count(*)                 AS cursos,
           sum(qt_ingressante)      AS ingressantes,
           sum(qt_permanencia)      AS seguem_no_curso,
           sum(qt_concluinte_acum)  AS concluiram,
           sum(qt_desistencia_acum) AS desistiram,
           sum(qt_falecido_acum)    AS faleceram,
           sum(qt_desistencia)      AS desistiram_no_ano
      FROM staging.trajetoria
     WHERE ano_ingresso = 2015
       AND modalidade = 'Presencial'
     GROUP BY ano_referencia, ano_do_curso
)
SELECT ano_referencia,
       ano_do_curso,
       cursos,
       ingressantes,
       CASE WHEN seguem_no_curso   >= 10 THEN seguem_no_curso   END AS seguem_no_curso,
       CASE WHEN concluiram        >= 10 THEN concluiram        END AS concluiram,
       CASE WHEN desistiram        >= 10 THEN desistiram        END AS desistiram,
       CASE WHEN faleceram         >= 10 THEN faleceram         END AS faleceram,
       CASE WHEN desistiram_no_ano >= 10 THEN desistiram_no_ano END AS desistiram_no_ano,
       CASE WHEN seguem_no_curso   >= 10 THEN round(100.0 * seguem_no_curso   / ingressantes, 1) END AS pct_seguem_no_curso,
       CASE WHEN concluiram        >= 10 THEN round(100.0 * concluiram        / ingressantes, 1) END AS pct_concluiram,
       CASE WHEN desistiram        >= 10 THEN round(100.0 * desistiram        / ingressantes, 1) END AS pct_desistiram,
       CASE WHEN faleceram         >= 10 THEN round(100.0 * faleceram         / ingressantes, 1) END AS pct_faleceram,
       CASE WHEN desistiram_no_ano >= 10 THEN round(100.0 * desistiram_no_ano / ingressantes, 1) END AS pct_desistiram_no_ano,
       desistiram_no_ano = max(desistiram_no_ano) OVER () AS ano_de_maior_perda
  FROM por_ano
 ORDER BY ano_referencia;
