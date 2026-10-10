-- P2 - Onde a rota mais se perde?
-- Desistência acumulada por curso e por área, sempre no mesmo ano do curso, para as turmas
-- de 2015 a 2020 serem comparáveis (a turma de 2020 só chega ao 5º ano em 2024).
-- Sigilo: curso ou área com menos de 10 ingressantes não aparece; só saem o total de
-- ingressantes e as taxas, nunca a contagem de desistentes ou concluintes.

-- Por área geral x turma x ano do curso
DROP TABLE IF EXISTS analytics.p2_desistencia_area;

CREATE TABLE analytics.p2_desistencia_area AS
SELECT co_area_geral,
       no_area_geral,
       ano_ingresso,
       ano_do_curso,
       count(*)                 AS cursos,
       sum(qt_ingressante)      AS ingressantes,
       round(100.0 * sum(qt_desistencia_acum) / sum(qt_ingressante), 1) AS pct_desistiram,
       round(100.0 * sum(qt_concluinte_acum)  / sum(qt_ingressante), 1) AS pct_concluiram
  FROM staging.trajetoria
 WHERE modalidade = 'Presencial'
 GROUP BY co_area_geral, no_area_geral, ano_ingresso, ano_do_curso
HAVING sum(qt_ingressante) >= 10
 ORDER BY ano_do_curso, ano_ingresso, pct_desistiram DESC;

-- Por curso x turma x ano do curso
DROP TABLE IF EXISTS analytics.p2_desistencia_curso;

CREATE TABLE analytics.p2_desistencia_curso AS
SELECT co_curso,
       no_curso,
       no_ies,
       rede,
       grau,
       no_area_geral,
       co_municipio,
       ano_ingresso,
       ano_do_curso,
       qt_ingressante AS ingressantes,
       round(100.0 * qt_desistencia_acum / qt_ingressante, 1) AS pct_desistiram,
       round(100.0 * qt_concluinte_acum  / qt_ingressante, 1) AS pct_concluiram,
       round(100.0 * qt_permanencia      / qt_ingressante, 1) AS pct_seguem_no_curso
  FROM staging.trajetoria
 WHERE modalidade = 'Presencial'
   AND qt_ingressante >= 10
 ORDER BY ano_do_curso, ano_ingresso, pct_desistiram DESC;

-- Ranking dos cursos no 5º ano, somando as seis turmas
DROP TABLE IF EXISTS analytics.p2_ranking_curso;

CREATE TABLE analytics.p2_ranking_curso AS
WITH no_5o_ano AS (
    SELECT co_curso,
           max(no_curso)            AS no_curso,
           max(no_ies)              AS no_ies,
           max(rede)                AS rede,
           max(grau)                AS grau,
           max(no_area_geral)       AS no_area_geral,
           count(*)                 AS turmas,
           sum(qt_ingressante)      AS ingressantes,
           sum(qt_desistencia_acum) AS desistiram
      FROM staging.trajetoria
     WHERE modalidade = 'Presencial'
       AND ano_do_curso = 5
     GROUP BY co_curso
    HAVING sum(qt_ingressante) >= 10
)
SELECT co_curso,
       no_curso,
       no_ies,
       rede,
       grau,
       no_area_geral,
       turmas,
       ingressantes,
       round(100.0 * desistiram / ingressantes, 1) AS pct_desistiram,
       rank() OVER (ORDER BY 100.0 * desistiram / ingressantes DESC) AS posicao_maior_desistencia,
       rank() OVER (ORDER BY 100.0 * desistiram / ingressantes)      AS posicao_menor_desistencia
  FROM no_5o_ano
 ORDER BY posicao_maior_desistencia;
