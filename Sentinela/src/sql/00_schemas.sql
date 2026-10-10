-- Camadas do projeto Sentinela. Pode rodar quantas vezes quiser.
CREATE SCHEMA IF NOT EXISTS raw;        -- cópia fiel dos arquivos, tudo como texto
CREATE SCHEMA IF NOT EXISTS staging;    -- tipos corrigidos, só MT
CREATE SCHEMA IF NOT EXISTS analytics;  -- uma tabela por pergunta, exportada para src/outputs/
