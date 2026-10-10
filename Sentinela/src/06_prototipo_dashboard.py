"""Dashboard em uma página HTML que abre sem banco e sem internet.

Uso:  python src/06_prototipo_dashboard.py                              lê os CSV de src/outputs/
      python src/06_prototipo_dashboard.py --api http://servidor:8000   lê da API; se falhar, usa os CSV

Grava src/dashboard/prototipo.html com os dados embutidos: depois de gerada, a página não
depende mais da API nem do banco.
"""
import argparse
import json
from datetime import datetime
from pathlib import Path

from fonte_dados import ler_tabela

RAIZ = Path(__file__).resolve().parents[1]
DESTINO = RAIZ / "src" / "dashboard" / "prototipo.html"
MODELO = Path(__file__).with_name("06_prototipo_modelo.html")
API = None
FONTES = {}


def ler(nome):
    linhas, fonte = ler_tabela(nome, API)
    FONTES[nome] = fonte
    return linhas


def num(valor):
    return float(valor) if valor not in ("", None) else None


def inteiro(valor):
    return int(float(valor))


def area_no_5o_ano():
    """Desistência por área no 5º ano do curso, somando as seis turmas (média ponderada)."""
    soma = {}
    for l in ler("p2_desistencia_area"):
        if inteiro(l["ano_do_curso"]) != 5:
            continue
        a = soma.setdefault(l["no_area_geral"], {"ing": 0.0, "des": 0.0})
        a["ing"] += num(l["ingressantes"])
        a["des"] += num(l["ingressantes"]) * num(l["pct_desistiram"]) / 100
    linhas = [{"area": k, "ingressantes": round(v["ing"]), "pct": round(100 * v["des"] / v["ing"], 1)}
              for k, v in soma.items()]
    return sorted(linhas, key=lambda x: -x["pct"])


MINIMO_RANKING = 50  # com poucas dezenas de ingressantes, um curso chega a 100% e distorce o ranking


def ranking(coluna_posicao, quantos=10):
    # a ordem das linhas da API não é garantida: ordena aqui, com o curso como desempate
    grandes = [l for l in ler("p2_ranking_curso") if inteiro(l["ingressantes"]) >= MINIMO_RANKING]
    linhas = sorted(grandes, key=lambda l: (inteiro(l[coluna_posicao]), l["co_curso"]))[:quantos]
    return [{"curso": l["no_curso"].title(), "ies": l["no_ies"], "rede": l["rede"],
             "ingressantes": inteiro(l["ingressantes"]), "pct": num(l["pct_desistiram"])} for l in linhas]


def main():
    global API
    p = argparse.ArgumentParser(description="Gera o dashboard em HTML.")
    p.add_argument("--api", help="endereço da API da equipe, por exemplo http://servidor:8000")
    API = p.parse_args().api

    dados = {
        "p1": sorted(({"ano": l["ano_referencia"], "ano_do_curso": inteiro(l["ano_do_curso"]),
                       "ingressantes": inteiro(l["ingressantes"]), "seguem": num(l["pct_seguem_no_curso"]),
                       "concluiram": num(l["pct_concluiram"]), "desistiram": num(l["pct_desistiram"]),
                       "no_ano": num(l["pct_desistiram_no_ano"]), "maior": l["ano_de_maior_perda"] == "True"}
                      for l in ler("p1_coorte_2015")), key=lambda x: x["ano_do_curso"]),
        "p2_area": area_no_5o_ano(),
        "p2_maior": ranking("posicao_maior_desistencia"),
        "p2_menor": ranking("posicao_menor_desistencia"),
        "p3": [{"ano": inteiro(l["ano"]), "grupo": f'{l["rede"]} · {l["modalidade"]}',
                "evasao": num(l["pct_evasao"]), "matriculas": inteiro(l["matriculas"]),
                "atipico": l["ano_atipico"] == "True"} for l in ler("p3_rede_modalidade")],
        "p4_fatores": sorted(({"fator": l["fator"], "categoria": l["categoria"], "cursos": inteiro(l["cursos"]),
                               "pct": num(l["pct_desistiram"])} for l in ler("p4_fatores")),
                             key=lambda x: (x["fator"], -x["pct"])),
        "p4_correlacao": sorted(({"indicador": l["indicador"], "cursos": inteiro(l["cursos"]),
                                  "r": num(l["correlacao_com_desistencia"])} for l in ler("p4_correlacao")),
                                key=lambda x: x["r"]),
        "p5_funil": [{"etapa": l["etapa"], "de_cada_100": num(l["de_cada_100"])}
                     for l in sorted(ler("p5_funil_resumo"), key=lambda l: inteiro(l["ordem"]))],
        "p5_area": [{"area": l["area_de_avaliacao"].title(), "cursos": inteiro(l["cursos"]),
                     "participantes": inteiro(l["concluintes_participantes"]), "pct": num(l["pct_proficientes"])}
                    for l in ler("p5_enade_area")],
    }
    usadas = set(FONTES.values())
    fonte = "API da equipe" if usadas == {"API"} else "arquivos exportados" if usadas == {"CSV"} else "API e arquivos exportados"
    dados["fonte"] = f"Dados lidos de: {fonte} · gerado em {datetime.now():%d/%m/%Y %H:%M}"

    html = MODELO.read_text(encoding="utf-8").replace("__DADOS__", json.dumps(dados, ensure_ascii=False))
    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    DESTINO.write_text(html, encoding="utf-8")
    print(f"fonte por tabela: {FONTES}")
    print(f"gravado: {DESTINO.relative_to(RAIZ)} ({DESTINO.stat().st_size / 1024:.0f} KB) · {dados['fonte']}")


if __name__ == "__main__":
    main()
