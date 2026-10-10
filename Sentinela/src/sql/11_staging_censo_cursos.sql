-- staging.censo_cursos: Censo de cursos de MT, agregado para uma linha por curso x ano.
-- No arquivo a linha é curso x município x ano; aqui as quantidades são somadas antes de
-- qualquer junção por co_curso. MT = linhas com co_uf = '51' (o EAD entra pelo município do polo).
DROP TABLE IF EXISTS staging.censo_cursos CASCADE;

CREATE TABLE staging.censo_cursos AS
SELECT trim(co_curso)                                   AS co_curso,
       nu_ano_censo::numeric::int                       AS ano,
       max(trim(no_curso))                              AS no_curso,
       max(trim(co_ies))                                AS co_ies,
       CASE max(trim(tp_rede)) WHEN '1' THEN 'Pública' WHEN '2' THEN 'Privada'
                               ELSE 'Não informado' END AS rede,
       CASE max(trim(tp_modalidade_ensino)) WHEN '1' THEN 'Presencial' WHEN '2' THEN 'EAD'
                                            ELSE 'Não informado' END AS modalidade,
       CASE max(trim(tp_grau_academico)) WHEN '1' THEN 'Bacharelado' WHEN '2' THEN 'Licenciatura'
                                         WHEN '3' THEN 'Tecnológico' ELSE 'Não informado' END AS grau,
       max(trim(co_cine_area_geral))                    AS co_area_geral,
       max(trim(no_cine_area_geral))                    AS no_area_geral,
       count(DISTINCT trim(co_municipio))               AS municipios,
       count(*)                                         AS linhas_no_arquivo,
       coalesce(sum(qt_mat::numeric), 0)::int              AS qt_mat,
       coalesce(sum(qt_ing::numeric), 0)::int              AS qt_ing,
       coalesce(sum(qt_conc::numeric), 0)::int             AS qt_conc,
       coalesce(sum(qt_vg_total::numeric), 0)::int         AS qt_vg_total,
       coalesce(sum(qt_sit_trancada::numeric), 0)::int     AS qt_trancada,
       coalesce(sum(qt_sit_desvinculado::numeric), 0)::int AS qt_desvinculado,
       coalesce(sum(qt_sit_transferido::numeric), 0)::int  AS qt_transferido,
       coalesce(sum(qt_sit_falecido::numeric), 0)::int     AS qt_falecido,
       coalesce(sum(qt_ing_fies::numeric), 0)::int         AS qt_ing_fies,
       coalesce(sum(qt_mat_fies::numeric), 0)::int         AS qt_mat_fies
  FROM raw.censo_cursos
 WHERE trim(co_uf) = '51'
 GROUP BY trim(co_curso), nu_ano_censo::numeric::int;

ALTER TABLE staging.censo_cursos ADD PRIMARY KEY (co_curso, ano);
