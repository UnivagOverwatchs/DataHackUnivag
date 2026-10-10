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
       + (SELECT count(*) FROM analytics.p2_ranking_curso WHERE ingressantes < 10)
UNION ALL
SELECT 'Censo: matrículas de MT em raw e em staging são iguais (2021 a 2024)',
       (SELECT sum(qt_mat::numeric) FROM raw.censo_cursos WHERE trim(co_uf) = '51'),
       (SELECT sum(qt_mat) FROM staging.censo_cursos)
UNION ALL
SELECT 'Censo: matrículas de MT em 2024 (exploração mediu 189.869)',
       189869,
       (SELECT sum(matriculas) FROM analytics.p3_rede_modalidade WHERE ano = 2024)
UNION ALL
SELECT 'Censo: cursos distintos de MT em 2024 (exploração mediu 3.890)',
       3890,
       (SELECT count(*) FROM staging.censo_cursos WHERE ano = 2024)
UNION ALL
SELECT 'P3: contagens publicadas abaixo de 10 alunos',
       0,
       (SELECT count(*) FROM analytics.p3_rede_modalidade
         WHERE least(matriculas, ingressantes, concluintes, trancados, desvinculados) < 10)
UNION ALL
SELECT 'CPC: cursos de MT em raw e em staging são iguais',
       (SELECT count(DISTINCT trim(codigo_do_curso)) FROM raw.cpc WHERE trim(sigla_da_uf) = 'MT'),
       (SELECT count(*) FROM staging.cpc)
UNION ALL
SELECT 'P4: cursos publicados com menos de 10 ingressantes',
       0,
       (SELECT count(*) FROM analytics.p4_curso WHERE ingressantes < 10)
UNION ALL
SELECT 'Enade Licenciaturas: cursos de MT em raw e em staging são iguais',
       (SELECT count(*) FROM raw.enade_licenciaturas WHERE trim(sigla_da_uf) = 'MT'),
       (SELECT count(*) FROM staging.enade_licenciaturas)
UNION ALL
SELECT 'P5: licenciaturas de MT na Trajetória (exploração mediu 129)',
       129,
       (SELECT count(DISTINCT co_curso) FROM staging.trajetoria WHERE grau = 'Licenciatura')
UNION ALL
SELECT 'P5: cursos, áreas ou turmas publicados com contagem abaixo de 10',
       0,
       (SELECT count(*) FROM analytics.p5_curso WHERE ingressantes < 10 OR concluintes_participantes < 10)
       + (SELECT count(*) FROM analytics.p5_enade_area WHERE concluintes_participantes < 10)
       + (SELECT count(*) FROM analytics.p5_funil_turma WHERE least(desistiram, concluiram, seguem_no_curso) < 10);

ALTER TABLE analytics.checagens ADD COLUMN ok boolean;
UPDATE analytics.checagens SET ok = (esperado = encontrado);
