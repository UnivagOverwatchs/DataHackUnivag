"""Fase 2 - protótipo do dashboard em uma página HTML que abre sem banco e sem internet.

Uso:  python src/06_prototipo_dashboard.py
Lê os CSV de src/outputs/ e grava src/dashboard/prototipo.html com os dados embutidos.
"""
import csv
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
SAIDAS = RAIZ / "src" / "outputs"
DESTINO = RAIZ / "src" / "dashboard" / "prototipo.html"
MODELO = Path(__file__).with_name("06_prototipo_modelo.html")


def ler(nome):
    with open(SAIDAS / f"{nome}.csv", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def num(valor):
    return float(valor) if valor not in ("", None) else None


def area_no_5o_ano():
    """Desistência por área no 5º ano do curso, somando as seis turmas (média ponderada)."""
    soma = {}
    for l in ler("p2_desistencia_area"):
        if l["ano_do_curso"] != "5":
            continue
        a = soma.setdefault(l["no_area_geral"], {"ing": 0.0, "des": 0.0})
        a["ing"] += num(l["ingressantes"])
        a["des"] += num(l["ingressantes"]) * num(l["pct_desistiram"]) / 100
    linhas = [{"area": k, "ingressantes": round(v["ing"]), "pct": round(100 * v["des"] / v["ing"], 1)}
              for k, v in soma.items()]
    return sorted(linhas, key=lambda x: -x["pct"])


def ranking(coluna_posicao, quantos=10):
    linhas = sorted(ler("p2_ranking_curso"), key=lambda l: int(l[coluna_posicao]))[:quantos]
    return [{"curso": l["no_curso"].title(), "ies": l["no_ies"], "rede": l["rede"],
             "ingressantes": int(float(l["ingressantes"])), "pct": num(l["pct_desistiram"])} for l in linhas]


def main():
    dados = {
        "p1": [{"ano": l["ano_referencia"], "ano_do_curso": int(l["ano_do_curso"]),
                "ingressantes": int(l["ingressantes"]), "seguem": num(l["pct_seguem_no_curso"]),
                "concluiram": num(l["pct_concluiram"]), "desistiram": num(l["pct_desistiram"]),
                "no_ano": num(l["pct_desistiram_no_ano"]), "maior": l["ano_de_maior_perda"] == "True"}
               for l in ler("p1_coorte_2015")],
        "p2_area": area_no_5o_ano(),
        "p2_maior": ranking("posicao_maior_desistencia"),
        "p2_menor": ranking("posicao_menor_desistencia"),
        "p3": [{"ano": int(l["ano"]), "grupo": f'{l["rede"]} · {l["modalidade"]}',
                "evasao": num(l["pct_evasao"]), "matriculas": int(l["matriculas"]),
                "atipico": l["ano_atipico"] == "True"} for l in ler("p3_rede_modalidade")],
        "p4_fatores": [{"fator": l["fator"], "categoria": l["categoria"], "cursos": int(l["cursos"]),
                        "pct": num(l["pct_desistiram"])} for l in ler("p4_fatores")],
        "p4_correlacao": [{"indicador": l["indicador"], "cursos": int(l["cursos"]),
                           "r": num(l["correlacao_com_desistencia"])} for l in ler("p4_correlacao")],
        "p5_funil": [{"etapa": l["etapa"], "de_cada_100": num(l["de_cada_100"])} for l in ler("p5_funil_resumo")],
        "p5_area": [{"area": l["area_de_avaliacao"].title(), "cursos": int(l["cursos"]),
                     "participantes": int(l["concluintes_participantes"]), "pct": num(l["pct_proficientes"])}
                    for l in ler("p5_enade_area")],
    }
    html = MODELO.read_text(encoding="utf-8").replace("__DADOS__", json.dumps(dados, ensure_ascii=False))
    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    DESTINO.write_text(html, encoding="utf-8")
    print(f"gravado: {DESTINO.relative_to(RAIZ)} ({DESTINO.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
