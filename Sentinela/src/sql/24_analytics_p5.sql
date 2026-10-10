-- P5 - O funil das licenciaturas
-- Quanto desiste, e quanto dos concluintes é proficiente no Enade das Licenciaturas 2025?
-- Trajetória: licenciaturas presenciais de MT, situação de cada turma em 2024.
-- Enade: percentual de concluintes participantes no padrão de proficiência ou acima.
-- Sigilo: só aparece curso ou área com 10 ingressantes / 10 participantes ou mais, e só a taxa de proficiência.

-- Situação em 2024 de cada turma de licenciatura (e de todas juntas)
DROP TABLE IF EXISTS analytics.p5_funil_turma CASCADE;

CREATE TABLE analytics.p5_funil_turma AS
SELECT coalesce(ano_ingresso::text, 'Todas') AS turma,
       count(*)                 AS cursos,
       sum(qt_ingressante)      AS ingressantes,
       sum(qt_desistencia_acum) AS desistiram,
       sum(qt_concluinte_acum)  AS concluiram,
       sum(qt_permanencia)      AS seguem_no_curso,
       round(100.0 * sum(qt_desistencia_acum) / sum(qt_ingressante), 1) AS pct_desistiram,
       round(100.0 * sum(qt_concluinte_acum)  / sum(qt_ingressante), 1) AS pct_concluiram,
       round(100.0 * sum(qt_permanencia)      / sum(qt_ingressante), 1) AS pct_seguem_no_curso
  FROM staging.trajetoria
 WHERE grau = 'Licenciatura'
   AND modalidade = 'Presencial'
   AND ano_referencia = 2024
 GROUP BY ROLLUP (ano_ingresso)
 ORDER BY turma;

-- Proficiência no Enade 2025 por área de avaliação (e no total de MT)
DROP TABLE IF EXISTS analytics.p5_enade_area CASCADE;

CREATE TABLE analytics.p5_enade_area AS
SELECT coalesce(area_de_avaliacao, 'Todas') AS area_de_avaliacao,
       count(*)                       AS cursos,
       sum(concluintes_participantes) AS concluintes_participantes,
       round(100.0 * sum(concluintes_proficientes) / sum(concluintes_participantes), 1) AS pct_proficientes
  FROM staging.enade_licenciaturas
 WHERE concluintes_proficientes IS NOT NULL
 GROUP BY ROLLUP (area_de_avaliacao)
HAVING sum(concluintes_participantes) >= 10
 ORDER BY pct_proficientes DESC;

-- O funil em uma tabela: de cada 100 que entram, quantos concluem e quantos concluem proficientes
DROP TABLE IF EXISTS analytics.p5_funil_resumo;

CREATE TABLE analytics.p5_funil_resumo AS
WITH t AS (SELECT * FROM analytics.p5_funil_turma WHERE turma = 'Todas'),
     e AS (SELECT * FROM analytics.p5_enade_area  WHERE area_de_avaliacao = 'Todas')
SELECT 1 AS ordem, 'Entraram na licenciatura (turmas de 2015 a 2020)' AS etapa, 100.0 AS de_cada_100, t.ingressantes AS alunos FROM t
UNION ALL
SELECT 2, 'Desistiram até 2024', t.pct_desistiram, t.desistiram FROM t
UNION ALL
SELECT 3, 'Seguiam no curso em 2024', t.pct_seguem_no_curso, t.seguem_no_curso FROM t
UNION ALL
SELECT 4, 'Concluíram até 2024', t.pct_concluiram, t.concluiram FROM t
UNION ALL
SELECT 5, 'Concluiriam proficientes, aplicando a taxa do Enade 2025 (' || e.pct_proficientes || '%) aos que concluíram',
       round(t.pct_concluiram * e.pct_proficientes / 100, 1), NULL FROM t, e
 ORDER BY ordem;

-- Curso a curso: desistência na Trajetória e proficiência no Enade
DROP TABLE IF EXISTS analytics.p5_curso;

CREATE TABLE analytics.p5_curso AS
WITH trajetoria AS (
    SELECT co_curso,
           max(no_curso)            AS no_curso,
           max(no_ies)              AS no_ies,
           max(rede)                AS rede,
           sum(qt_ingressante)      AS ingressantes,
           sum(qt_desistencia_acum) AS desistiram,
           sum(qt_concluinte_acum)  AS concluiram
      FROM staging.trajetoria
     WHERE grau = 'Licenciatura'
       AND modalidade = 'Presencial'
       AND ano_referencia = 2024
     GROUP BY co_curso
    HAVING sum(qt_ingressante) >= 10
)
SELECT t.co_curso,
       t.no_curso,
       t.no_ies,
       t.rede,
       e.area_de_avaliacao,
       t.ingressantes,
       round(100.0 * t.desistiram / t.ingressantes, 1) AS pct_desistiram,
       round(100.0 * t.concluiram / t.ingressantes, 1) AS pct_concluiram,
       e.concluintes_participantes,
       round(e.pct_proficientes, 1)                    AS pct_proficientes,
       e.conceito_enade_faixa
  FROM trajetoria t
  JOIN staging.enade_licenciaturas e USING (co_curso)
 WHERE e.concluintes_participantes >= 10
   AND e.pct_proficientes IS NOT NULL
 ORDER BY pct_proficientes DESC;
