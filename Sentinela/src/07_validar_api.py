"""Fase 3 - confere se a API devolve os mesmos dados que os CSV exportados da camada analytics.

Uso:  python src/07_validar_api.py --api http://servidor:8000
Para cada tabela compara número de linhas, colunas e valores, e grava src/outputs/validacao_api.csv.
"""
import argparse
import csv
from pathlib import Path

from fonte_dados import LIMITE, SAIDAS, ler_api, ler_csv

RESULTADO = SAIDAS / "validacao_api.csv"


def normalizar(valor):
    """Mesmo valor escrito de dois jeitos conta como igual: '6.80' e '6.8', '' e nulo."""
    try:
        return round(float(valor), 6)
    except (TypeError, ValueError):
        return (valor or "").strip()


def chave(linha, colunas):
    return tuple(str(normalizar(linha.get(c))) for c in colunas)


def comparar(nome, api):
    arquivo = ler_csv(nome)
    registro = {"tabela": f"analytics.{nome}", "linhas_csv": len(arquivo)}
    try:
        servico = ler_api(nome, api)
    except Exception as erro:
        return registro | {"linhas_api": "", "colunas_iguais": "", "linhas_diferentes": "",
                           "ok": False, "observacao": f"API não respondeu: {type(erro).__name__}"}
    if len(arquivo) > LIMITE:  # a API corta em LIMITE linhas e não pagina: não dá para comparar inteira
        return registro | {"linhas_api": len(servico), "colunas_iguais": "", "linhas_diferentes": "",
                           "ok": len(servico) == LIMITE,
                           "observacao": f"tabela maior que o limite da API ({LIMITE} linhas); comparado só o corte"}
    colunas = list(arquivo[0]) if arquivo else []
    colunas_api = list(servico[0]) if servico else []
    # a ordem das linhas da API não é garantida: compara os conjuntos ordenados
    a, b = sorted(chave(l, colunas) for l in arquivo), sorted(chave(l, colunas) for l in servico)
    diferentes = sum(x != y for x, y in zip(a, b)) + abs(len(a) - len(b))
    iguais = set(colunas) == set(colunas_api)
    return registro | {"linhas_api": len(servico), "colunas_iguais": iguais, "linhas_diferentes": diferentes,
                       "ok": iguais and diferentes == 0, "observacao": ""}


def main():
    p = argparse.ArgumentParser(description="Compara a API com os CSV exportados.")
    p.add_argument("--api", required=True, help="endereço da API da equipe, por exemplo http://servidor:8000")
    api = p.parse_args().api

    tabelas = sorted(a.stem for a in SAIDAS.glob("*.csv") if a.stem.startswith(("p", "b", "checagens")))
    registros = [comparar(nome, api) for nome in tabelas]
    with open(RESULTADO, "w", encoding="utf-8-sig", newline="") as f:
        escritor = csv.DictWriter(f, fieldnames=list(registros[0]))
        escritor.writeheader()
        escritor.writerows(registros)
    for r in registros:
        print(f"{'OK   ' if r['ok'] else 'DIFERE'} {r['tabela']:<34} csv {r['linhas_csv']:>6}  api {r['linhas_api']:>6}  "
              f"linhas diferentes: {r['linhas_diferentes']} {r['observacao']}")
    falhas = sum(not r["ok"] for r in registros)
    print("a API devolve o mesmo que os arquivos exportados" if not falhas else f"{falhas} tabela(s) com diferença")


if __name__ == "__main__":
    main()
