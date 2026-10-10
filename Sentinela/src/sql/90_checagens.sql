-- Checagens de qualidade. Cada linha é um teste: "ok" verdadeiro quando o encontrado bate com o esperado.
DROP TABLE IF EXISTS analytics.checagens;

CREATE TABLE analytics.checagens AS
SELECT 'Trajetória: linhas de MT em raw e em staging são iguais' AS checagem,
       (SELECT count(DISTINCT (co_curso, nu_ano_ingresso, nu_ano_referencia))
          FROM raw.trajetoria WHERE trim(co_uf) = '51')::numeric AS esperado,
       (SELECT count(*) FROM staging.trajetoria)::numeric        AS encontrado
UNION ALL
SELECT 'Trajetória: cursos distintos de MT (exploração mediu 784)',
       784,
       (SELECT count(DISTINCT co_curso) FROM staging.trajetoria)
UNION ALL
SELECT 'Trajetória: linhas em que TAP + TCA + TDA não fecha 100',
       0,
       (SELECT count(*) FROM staging.trajetoria WHERE abs(tap + tca + tda - 100) > 0.5)
UNION ALL
SELECT 'Trajetória: linhas em que seguem + concluíram + desistiram + faleceram difere de ingressantes',
       0,
       (SELECT count(*) FROM staging.trajetoria
         WHERE qt_permanencia + qt_concluinte_acum + qt_desistencia_acum + qt_falecido_acum <> qt_ingressante)
UNION ALL
SELECT 'Trajetória: linhas em que a desistência acumulada calculada difere da TDA do INEP',
       0,
       (SELECT count(*) FROM staging.trajetoria
         WHERE qt_ingressante - qt_falecido_acum > 0
           AND abs(100.0 * qt_desistencia_acum / (qt_ingressante - qt_falecido_acum) - tda) > 0.01)
UNION ALL
SELECT 'Trajetória: códigos de curso, município ou área nulos',
       0,
       (SELECT count(*) FROM staging.trajetoria
         WHERE co_curso IS NULL OR co_municipio IS NULL OR co_area_geral IS NULL)
UNION ALL
SELECT 'P1: ingressantes da turma de 2015 presencial (exploração mediu 41.918)',
       41918,
       (SELECT max(ingressantes) FROM analytics.p1_coorte_2015)
UNION ALL
SELECT 'P1: contagens publicadas abaixo de 10 alunos',
       0,
       (SELECT count(*) FROM analytics.p1_coorte_2015
         WHERE least(seguem_no_curso, concluiram, desistiram, faleceram, desistiram_no_ano) < 10)
UNION ALL
SELECT 'P2: cursos publicados com menos de 10 ingressantes',
       0,
       (SELECT count(*) FROM analytics.p2_desistencia_curso WHERE ingressantes < 10)
       + (SELECT count(*) FROM analytics.p2_ranking_curso WHERE ingressantes < 10);

ALTER TABLE analytics.checagens ADD COLUMN ok boolean;
UPDATE analytics.checagens SET ok = (esperado = encontrado);
