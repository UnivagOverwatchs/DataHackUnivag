-- P3 - Pública x privada, presencial x EAD
-- Matrículas e evasão anual por rede e modalidade, 2021 a 2024, e se há ano atípico.
-- Evasão anual = desvinculados no ano / alunos com vínculo no ano
--   (vínculo = matriculados + trancados + desvinculados + transferidos + falecidos).
-- Ano atípico = evasão do ano pelo menos o dobro da mediana dos quatro anos do mesmo grupo (rede x modalidade).
-- Sigilo: transferidos e falecidos entram na conta do vínculo, mas não são publicados (há células abaixo de 10).
DROP TABLE IF EXISTS analytics.p3_rede_modalidade;

CREATE TABLE analytics.p3_rede_modalidade AS
WITH grupo AS (
    SELECT ano,
           rede,
           modalidade,
           count(*)             AS cursos,
           sum(qt_mat)          AS matriculas,
           sum(qt_ing)          AS ingressantes,
           sum(qt_conc)         AS concluintes,
           sum(qt_trancada)     AS trancados,
           sum(qt_desvinculado) AS desvinculados,
           sum(qt_mat + qt_trancada + qt_desvinculado + qt_transferido + qt_falecido) AS vinculos
      FROM staging.censo_cursos
     WHERE ano BETWEEN 2021 AND 2024
     GROUP BY ano, rede, modalidade
), com_taxa AS (
    SELECT grupo.*,
           100.0 * desvinculados / vinculos AS evasao
      FROM grupo
), mediana AS (
    SELECT rede,
           modalidade,
           percentile_cont(0.5) WITHIN GROUP (ORDER BY evasao)::numeric AS evasao_mediana
      FROM com_taxa
     GROUP BY rede, modalidade
), comparado AS (
    SELECT com_taxa.*,
           mediana.evasao_mediana,
           lag(matriculas) OVER (PARTITION BY rede, modalidade ORDER BY ano) AS matriculas_ano_anterior
      FROM com_taxa
      JOIN mediana USING (rede, modalidade)
)
SELECT ano,
       rede,
       modalidade,
       cursos,
       matriculas,
       ingressantes,
       concluintes,
       trancados,
       desvinculados,
       vinculos,
       round(evasao, 1)         AS pct_evasao,
       round(evasao_mediana, 1) AS pct_evasao_mediana_do_grupo,
       round(100.0 * (matriculas - matriculas_ano_anterior) / matriculas_ano_anterior, 1) AS pct_variacao_matriculas,
       evasao >= 2 * evasao_mediana AS ano_atipico
  FROM comparado
 ORDER BY rede, modalidade, ano;
