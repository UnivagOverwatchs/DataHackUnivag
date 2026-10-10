-- staging.trajetoria: Trajetória de MT com tipos corrigidos. Pode rodar quantas vezes quiser.
-- Uma linha por curso x turma (ano de ingresso) x ano de referência.
-- Os códigos ficam como texto; as quantidades do ano ganham a versão acumulada.
DROP TABLE IF EXISTS staging.trajetoria CASCADE;

CREATE TABLE staging.trajetoria AS
WITH base AS (
    -- se o mesmo arquivo tiver sido carregado com e sem --so-mt, fica uma linha só por chave
    SELECT DISTINCT ON (co_curso, nu_ano_ingresso, nu_ano_referencia)
           trim(co_curso)                               AS co_curso,
           trim(no_curso)                               AS no_curso,
           trim(co_ies)                                 AS co_ies,
           trim(no_ies)                                 AS no_ies,
           trim(co_municipio)                           AS co_municipio,
           trim(tp_categoria_administrativa)            AS tp_categoria_administrativa,
           trim(tp_grau_academico)                      AS tp_grau_academico,
           trim(tp_modalidade_ensino)                   AS tp_modalidade_ensino,
           trim(co_cine_area_geral)                     AS co_area_geral,
           trim(no_cine_area_geral)                     AS no_area_geral,
           trim(co_cine_rotulo)                         AS co_cine_rotulo,
           trim(no_cine_rotulo)                         AS no_cine_rotulo,
           nu_ano_ingresso::numeric::int                AS ano_ingresso,
           nu_ano_referencia::numeric::int              AS ano_referencia,
           nu_prazo_integralizacao::numeric::int        AS prazo_integralizacao,
           nu_ano_maximo_acompanhamento::numeric::int   AS ano_maximo_acompanhamento,
           qt_ingressante::numeric::int                 AS qt_ingressante,
           qt_permanencia::numeric::int                 AS qt_permanencia,
           qt_concluinte::numeric::int                  AS qt_concluinte,
           qt_desistencia::numeric::int                 AS qt_desistencia,
           qt_falecido::numeric::int                    AS qt_falecido,
           tap::numeric                                 AS tap,
           tca::numeric                                 AS tca,
           tda::numeric                                 AS tda,
           tcan::numeric                                AS tcan,
           tada::numeric                                AS tada,
           arquivo_origem
      FROM raw.trajetoria
     WHERE trim(co_uf) = '51'
     ORDER BY co_curso, nu_ano_ingresso, nu_ano_referencia, carregado_em DESC
)
SELECT base.*,
       ano_referencia - ano_ingresso + 1 AS ano_do_curso,  -- 1 = ano em que a turma entrou
       CASE WHEN tp_categoria_administrativa IN ('1', '2', '3') THEN 'Pública'
            WHEN tp_categoria_administrativa IN ('4', '5')      THEN 'Privada'
            ELSE 'Especial' END AS rede,
       CASE tp_grau_academico WHEN '1' THEN 'Bacharelado' WHEN '2' THEN 'Licenciatura'
                              WHEN '3' THEN 'Tecnológico' ELSE 'Não informado' END AS grau,
       CASE tp_modalidade_ensino WHEN '1' THEN 'Presencial' WHEN '2' THEN 'EAD'
                                 ELSE 'Não informado' END AS modalidade,
       sum(qt_concluinte)  OVER turma AS qt_concluinte_acum,
       sum(qt_desistencia) OVER turma AS qt_desistencia_acum,
       sum(qt_falecido)    OVER turma AS qt_falecido_acum
  FROM base
WINDOW turma AS (PARTITION BY co_curso, ano_ingresso ORDER BY ano_referencia);

ALTER TABLE staging.trajetoria ADD PRIMARY KEY (co_curso, ano_ingresso, ano_referencia);
