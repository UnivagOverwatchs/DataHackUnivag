"""Fase 1 - perfil dos arquivos do Censo da Educação Superior (cursos e IES).

Uso:  python src/01_exploracao_censo.py
Lê os CSV de Dados/ e grava src/outputs/exploracao_censo.csv.
"""
from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
DADOS = RAIZ / "Dados"
SAIDA = RAIZ / "src" / "outputs" / "exploracao_censo.csv"
UF_MT = "51"


def ler(arquivo, colunas):
    # códigos como texto; o INEP usa ; e latin-1
    return pd.read_csv(arquivo, sep=";", encoding="latin-1", dtype=str, usecols=colunas)


def perfil_cursos(arquivo):
    colunas = ["CO_UF", "CO_MUNICIPIO", "CO_IES", "CO_CURSO", "TP_REDE",
               "TP_MODALIDADE_ENSINO", "QT_MAT", "QT_ING", "QT_VG_TOTAL"]
    df = ler(arquivo, colunas)
    mt = df[df["CO_UF"] == UF_MT]
    ead = df[df["TP_MODALIDADE_ENSINO"] == "2"]
    return {
        "arquivo": arquivo.name,
        "tamanho_mb": round(arquivo.stat().st_size / 1e6),
        "colunas": len(pd.read_csv(arquivo, sep=";", encoding="latin-1", nrows=0).columns),
        "linhas": len(df),
        "linhas_mt": len(mt),
        "cursos_distintos_mt": mt["CO_CURSO"].nunique(),
        "linhas_mt_repetindo_curso": len(mt) - mt["CO_CURSO"].nunique(),
        "municipios_mt": mt["CO_MUNICIPIO"].nunique(),
        "ies_mt": mt["CO_IES"].nunique(),
        "linhas_mt_presencial": (mt["TP_MODALIDADE_ENSINO"] == "1").sum(),
        "linhas_mt_ead": (mt["TP_MODALIDADE_ENSINO"] == "2").sum(),
        "linhas_ead_sem_uf": ead["CO_UF"].isna().sum(),
        "soma_qt_mat_mt": pd.to_numeric(mt["QT_MAT"]).sum(),
        "soma_qt_ing_mt": pd.to_numeric(mt["QT_ING"]).sum(),
    }


def perfil_ies(arquivo):
    df = ler(arquivo, ["CO_IES", "CO_UF_IES", "CO_MUNICIPIO_IES"])
    return {
        "arquivo": arquivo.name,
        "tamanho_mb": round(arquivo.stat().st_size / 1e6),
        "colunas": len(pd.read_csv(arquivo, sep=";", encoding="latin-1", nrows=0).columns),
        "linhas": len(df),
        "linhas_mt": (df["CO_UF_IES"] == UF_MT).sum(),
        "co_ies_repetido": len(df) - df["CO_IES"].nunique(),
    }


def main():
    linhas = [perfil_cursos(a) for a in sorted(DADOS.rglob("MICRODADOS_CADASTRO_CURSOS_*.CSV"))]
    linhas += [perfil_ies(a) for a in sorted(DADOS.rglob("MICRODADOS_*IES_*.CSV"))]
    resultado = pd.DataFrame(linhas)
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    resultado.to_csv(SAIDA, index=False)
    print(resultado.to_string(index=False))


if __name__ == "__main__":
    main()
