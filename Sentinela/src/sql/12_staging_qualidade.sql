-- staging.cpc e staging.enade_licenciaturas: indicadores de qualidade de MT, uma linha por curso.
-- Nota que não é número (por exemplo "SC", sem conceito) vira nulo em vez de quebrar a carga.
CREATE OR REPLACE FUNCTION staging.para_numero(texto text) RETURNS numeric
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE WHEN trim(texto) ~ '^-?[0-9]+(\.[0-9]+)?$' THEN trim(texto)::numeric END
$$;

DROP TABLE IF EXISTS staging.cpc CASCADE;

CREATE TABLE staging.cpc AS
SELECT DISTINCT ON (trim(codigo_do_curso))  -- se o curso foi avaliado em mais de uma edição, fica a mais recente
       trim(codigo_do_curso)                                AS co_curso,
       ano::numeric::int                                    AS ano_cpc,
       trim(area_de_avaliacao)                              AS area_de_avaliacao,
       CASE WHEN modalidade_de_ensino ILIKE '%dist%' THEN 'EAD' ELSE 'Presencial' END AS modalidade,
       staging.para_numero(no_de_concluintes_participantes)::int AS concluintes_participantes,
       staging.para_numero(cpc_continuo)                    AS cpc_continuo,
       trim(cpc_faixa)                                      AS cpc_faixa,  -- 1 a 5, ou SC (sem conceito)
       staging.para_numero(conceito_enade_continuo)         AS conceito_enade_continuo,
       staging.para_numero(nota_padronizada_idd)            AS nota_idd,
       staging.para_numero(nota_padronizada_organizacao_didatico_pedagogica)       AS nota_organizacao_didatica,
       staging.para_numero(nota_padronizada_infraestrutura_e_instalacoes_fisicas)  AS nota_infraestrutura,
       staging.para_numero(nota_padronizada_oportunidade_de_ampliacao_da_formacao) AS nota_oportunidades,
       staging.para_numero(nota_padronizada_mestres)        AS nota_mestres,
       staging.para_numero(nota_padronizada_doutores)       AS nota_doutores,
       staging.para_numero(nota_padronizada_regime_de_trabalho) AS nota_regime_de_trabalho,
       arquivo_origem
  FROM raw.cpc
 WHERE trim(sigla_da_uf) = 'MT'
 ORDER BY trim(codigo_do_curso), ano::numeric::int DESC;

ALTER TABLE staging.cpc ADD PRIMARY KEY (co_curso);

DROP TABLE IF EXISTS staging.enade_licenciaturas CASCADE;

CREATE TABLE staging.enade_licenciaturas AS
SELECT trim(codigo_do_curso)                                AS co_curso,
       ano::numeric::int                                    AS ano_enade,
       trim(area_de_avaliacao)                              AS area_de_avaliacao,
       CASE WHEN modalidade_de_ensino ILIKE 'ead%' OR modalidade_de_ensino ILIKE '%dist%'
            THEN 'EAD' ELSE 'Presencial' END                AS modalidade,
       staging.para_numero(no_de_concluintes_inscritos)::int      AS concluintes_inscritos,
       staging.para_numero(no_de_concluintes_participantes)::int  AS concluintes_participantes,
       staging.para_numero(total_de_concluinte_igual_ou_acima_do_padrao_1_de_proficienc)::int AS concluintes_proficientes,
       100 * staging.para_numero(percentual_de_concluintes_igual_ou_acima_do_padrao_1_de_prof) AS pct_proficientes,
       trim(conceito_enade_faixa)                           AS conceito_enade_faixa,
       arquivo_origem
  FROM raw.enade_licenciaturas
 WHERE trim(sigla_da_uf) = 'MT';

ALTER TABLE staging.enade_licenciaturas ADD PRIMARY KEY (co_curso);
