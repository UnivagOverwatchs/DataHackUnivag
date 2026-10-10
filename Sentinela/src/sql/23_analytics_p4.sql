-- P4 - Qualidade retém?
-- Cursos com CPC mais alto têm desistência menor? E o que mais se associa à desistência?
-- Desistência = acumulada no 5º ano do curso, somando as turmas de 2015 a 2020 (presencial).
-- Só entram cursos com CPC numérico e 10 ingressantes ou mais; a cobertura fica nas checagens.
-- Os dados são agregados: as tabelas mostram associação, não causa.

-- Um curso por linha: desistência e CPC lado a lado
DROP TABLE IF EXISTS analytics.p4_curso CASCADE;

CREATE TABLE analytics.p4_curso AS
WITH desistencia AS (
    SELECT co_curso,
           max(no_curso)            AS no_curso,
           max(no_ies)              AS no_ies,
           max(rede)                AS rede,
           max(grau)                AS grau,
           max(no_area_geral)       AS no_area_geral,
           sum(qt_ingressante)      AS ingressantes,
           sum(qt_desistencia_acum) AS desistiram
      FROM staging.trajetoria
     WHERE modalidade = 'Presencial'
       AND ano_do_curso = 5
     GROUP BY co_curso
    HAVING sum(qt_ingressante) >= 10
)
SELECT d.co_curso,
       d.no_curso,
       d.no_ies,
       d.rede,
       d.grau,
       d.no_area_geral,
       d.ingressantes,
       round(100.0 * d.desistiram / d.ingressantes, 1) AS pct_desistiram,
       c.ano_cpc,
       round(c.cpc_continuo, 3)                        AS cpc_continuo,
       c.cpc_faixa,
       c.conceito_enade_continuo,
       c.nota_idd,
       c.nota_organizacao_didatica,
       c.nota_infraestrutura,
       c.nota_oportunidades,
       c.nota_mestres,
       c.nota_doutores,
       c.nota_regime_de_trabalho
  FROM desistencia d
  JOIN staging.cpc c USING (co_curso)
 WHERE c.cpc_continuo IS NOT NULL
 ORDER BY c.cpc_continuo DESC;

-- Desistência por característica do curso. A amplitude (maior menos menor) mostra o que mais separa os cursos.
DROP TABLE IF EXISTS analytics.p4_fatores;

CREATE TABLE analytics.p4_fatores AS
WITH longo AS (
    SELECT 'Faixa do CPC' AS fator, cpc_faixa AS categoria, ingressantes, pct_desistiram FROM analytics.p4_curso
    UNION ALL
    SELECT 'Rede', rede, ingressantes, pct_desistiram FROM analytics.p4_curso
    UNION ALL
    SELECT 'Grau', grau, ingressantes, pct_desistiram FROM analytics.p4_curso
    UNION ALL
    SELECT 'Área', no_area_geral, ingressantes, pct_desistiram FROM analytics.p4_curso
), resumo AS (
    SELECT fator,
           categoria,
           count(*)          AS cursos,
           sum(ingressantes) AS ingressantes,
           round(sum(pct_desistiram * ingressantes) / sum(ingressantes), 1) AS pct_desistiram
      FROM longo
     GROUP BY fator, categoria
)
SELECT resumo.*,
       max(pct_desistiram) OVER (PARTITION BY fator) - min(pct_desistiram) OVER (PARTITION BY fator) AS amplitude_do_fator
  FROM resumo
 ORDER BY amplitude_do_fator DESC, fator, pct_desistiram DESC;

-- Correlação entre cada nota do INEP e a desistência do curso (de -1 a 1; negativa = nota maior, desistência menor)
DROP TABLE IF EXISTS analytics.p4_correlacao;

CREATE TABLE analytics.p4_correlacao AS
SELECT indicador,
       count(*)                                      AS cursos,
       round(corr(nota, pct_desistiram)::numeric, 3) AS correlacao_com_desistencia
  FROM analytics.p4_curso
 CROSS JOIN LATERAL (VALUES
       ('CPC (contínuo)',                         cpc_continuo),
       ('Conceito Enade (contínuo)',              conceito_enade_continuo),
       ('IDD',                                    nota_idd),
       ('Organização didático-pedagógica',        nota_organizacao_didatica),
       ('Infraestrutura',                         nota_infraestrutura),
       ('Oportunidades de ampliação da formação', nota_oportunidades),
       ('Mestres',                                nota_mestres),
       ('Doutores',                               nota_doutores),
       ('Regime de trabalho',                     nota_regime_de_trabalho)
     ) AS n(indicador, nota)
 WHERE nota IS NOT NULL
 GROUP BY indicador
 ORDER BY correlacao_com_desistencia;
