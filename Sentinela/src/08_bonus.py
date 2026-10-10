"""Fase 3 - perguntas bônus B1 e B2, calculadas direto dos arquivos (Censo 2021-2024 e IBGE 9514).

Uso:  python src/08_bonus.py
Grava em src/outputs/: b1_vagas_por_jovens.csv, b2_financiamento_ano.csv e b2_financiamento_evasao.csv.
Atenção: por falta de tempo, este cálculo lê os arquivos de Dados/ e não passa pelas camadas do banco.
"""
import json
import re
from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parents[1]
DADOS = RAIZ / "Dados"
SAIDAS = RAIZ / "src" / "outputs"
COLUNAS = ["NU_ANO_CENSO", "CO_UF", "CO_MUNICIPIO", "NO_MUNICIPIO", "CO_CURSO", "TP_REDE", "TP_MODALIDADE_ENSINO",
           "QT_VG_TOTAL", "QT_MAT", "QT_MAT_FIES", "QT_MAT_PROUNII", "QT_MAT_PROUNIP",
           "QT_SIT_DESVINCULADO", "QT_SIT_TRANCADA", "QT_SIT_TRANSFERIDO", "QT_SIT_FALECIDO"]


def censo_mt():
    partes = []
    for ano in ("2021", "2022", "2023", "2024"):
        arquivo = next(DADOS.rglob(f"MICRODADOS_CADASTRO_CURSOS_{ano}.CSV"))
        df = pd.read_csv(arquivo, sep=";", encoding="latin-1", dtype=str, usecols=lambda c: c in COLUNAS)
        partes.append(df[df["CO_UF"] == "51"])
    df = pd.concat(partes, ignore_index=True)
    for c in [c for c in df.columns if c.startswith("QT_")]:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0)
    return df


def b2(df):
    priv = df[df["TP_REDE"] == "2"].copy()
    priv["prouni"] = priv["QT_MAT_PROUNII"] + priv["QT_MAT_PROUNIP"]
    ano = priv.groupby("NU_ANO_CENSO")[["QT_MAT", "QT_MAT_FIES", "prouni"]].sum().reset_index()
    ano.columns = ["ano", "matriculas_rede_privada", "matriculas_fies", "matriculas_prouni"]
    ano["pct_fies"] = (100 * ano["matriculas_fies"] / ano["matriculas_rede_privada"]).round(1)
    ano["pct_prouni"] = (100 * ano["matriculas_prouni"] / ano["matriculas_rede_privada"]).round(1)
    ano.to_csv(SAIDAS / "b2_financiamento_ano.csv", index=False, encoding="utf-8-sig")

    # curso x ano: parcela de matrículas com financiamento e evasão anual (mesma conta da P3)
    c = priv.groupby(["CO_CURSO", "NU_ANO_CENSO"])[["QT_MAT", "QT_MAT_FIES", "prouni", "QT_SIT_DESVINCULADO",
                                                     "QT_SIT_TRANCADA", "QT_SIT_TRANSFERIDO", "QT_SIT_FALECIDO"]].sum()
    c["vinculos"] = c[["QT_MAT", "QT_SIT_DESVINCULADO", "QT_SIT_TRANCADA", "QT_SIT_TRANSFERIDO", "QT_SIT_FALECIDO"]].sum(axis=1)
    c = c[(c["QT_MAT"] >= 10) & (c["vinculos"] >= 30)].copy()
    c["pct_financiados"] = 100 * (c["QT_MAT_FIES"] + c["prouni"]).clip(upper=c["QT_MAT"]) / c["QT_MAT"]
    c["pct_evasao"] = 100 * c["QT_SIT_DESVINCULADO"] / c["vinculos"]
    c["faixa"] = pd.cut(c["pct_financiados"], [-0.01, 0, 10, 100], labels=["Sem financiados", "Até 10% financiados", "Mais de 10% financiados"])
    faixa = c.groupby("faixa", observed=True).agg(cursos_ano=("QT_MAT", "size"), matriculas=("QT_MAT", "sum"),
                                                    desvinculados=("QT_SIT_DESVINCULADO", "sum"), vinculos=("vinculos", "sum")).reset_index()
    faixa["pct_evasao"] = (100 * faixa["desvinculados"] / faixa["vinculos"]).round(1)
    faixa["correlacao_financiados_x_evasao"] = round(c["pct_financiados"].corr(c["pct_evasao"]), 3)
    faixa.to_csv(SAIDAS / "b2_financiamento_evasao.csv", index=False, encoding="utf-8-sig")
    return ano, faixa


def jovens_18_24():
    arquivo = next((DADOS / "IBGE").rglob("tabela_9514_populacao_*.json"))
    dados = json.loads(arquivo.read_text(encoding="utf-8"))
    soma, usadas = {}, set()
    for variavel in dados:
        if "percentual" in variavel["variavel"].lower():
            continue
        for r in variavel["resultados"]:
            cat = {c["nome"]: next(iter(c["categoria"].values())) for c in r["classificacoes"]}
            idade = cat.get("Idade", "")
            m = re.fullmatch(r"(\d+) anos?", idade)
            if not m or not 18 <= int(m.group(1)) <= 24 or cat.get("Sexo") != "Total":
                continue
            if any(v != "Total" for k, v in cat.items() if k not in ("Idade", "Sexo")):
                continue
            usadas.add(idade)
            for s in r["series"]:
                valor = next(iter(s["serie"].values()))
                reg = soma.setdefault(s["localidade"]["id"], {"municipio": s["localidade"]["nome"], "jovens_18_24": 0})
                reg["jovens_18_24"] += int(valor) if str(valor).isdigit() else 0
    return pd.DataFrame([{"co_municipio": k, **v} for k, v in soma.items()]), sorted(usadas)


def b1(df):
    pres = df[(df["NU_ANO_CENSO"] == "2024") & (df["TP_MODALIDADE_ENSINO"] == "1")]
    vagas = pres.groupby("CO_MUNICIPIO")["QT_VG_TOTAL"].sum().rename("vagas_presenciais_2024").reset_index()
    jovens, idades = jovens_18_24()
    t = jovens.merge(vagas, left_on="co_municipio", right_on="CO_MUNICIPIO", how="left").drop(columns="CO_MUNICIPIO")
    t["vagas_presenciais_2024"] = t["vagas_presenciais_2024"].fillna(0).astype(int)
    t["vagas_por_100_jovens"] = (100 * t["vagas_presenciais_2024"] / t["jovens_18_24"]).round(1)
    t["sem_oferta_presencial"] = t["vagas_presenciais_2024"] == 0
    t = t.sort_values("vagas_por_100_jovens", ascending=False)
    t.to_csv(SAIDAS / "b1_vagas_por_jovens.csv", index=False, encoding="utf-8-sig")
    return t, idades


def main():
    df = censo_mt()
    ano, faixa = b2(df)
    print("== B2: peso de FIES e ProUni na rede privada de MT ==")
    print(ano.to_string(index=False))
    print(faixa.to_string(index=False))
    t, idades = b1(df)
    sem = t[t["sem_oferta_presencial"]]
    print("\n== B1: vagas presenciais por 100 jovens de 18 a 24 anos (2024) ==")
    print("idades somadas:", idades)
    print(f"municípios: {len(t)} | sem oferta presencial: {len(sem)} | jovens nesses municípios: {int(sem['jovens_18_24'].sum())} de {int(t['jovens_18_24'].sum())}")
    print(f"MT: {int(t['vagas_presenciais_2024'].sum())} vagas para {int(t['jovens_18_24'].sum())} jovens = {100 * t['vagas_presenciais_2024'].sum() / t['jovens_18_24'].sum():.1f} por 100")
    print(t.head(8).to_string(index=False))
    print("maiores municípios sem oferta:")
    print(sem.sort_values("jovens_18_24", ascending=False).head(5)[["municipio", "jovens_18_24"]].to_string(index=False))


if __name__ == "__main__":
    main()
