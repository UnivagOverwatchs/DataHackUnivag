"""Fase 2 - transformação: roda os SQL de src/sql/ em ordem e exporta analytics para src/outputs/.

Uso:  python src/05_transformacao.py

Cada arquivo .sql roda em uma transação e recria as suas tabelas do zero, então pode rodar
quantas vezes quiser. No fim, cada tabela do schema analytics vira um CSV em src/outputs/
(é deles que o dashboard lê) e as checagens de qualidade são mostradas na tela.
O acesso ao banco vem do .env, como na carga.
"""
import csv
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg import sql

RAIZ = Path(__file__).resolve().parents[1]
SQL = RAIZ / "src" / "sql"
SAIDAS = RAIZ / "src" / "outputs"


def rodar_sql(conn):
    for arquivo in sorted(SQL.glob("*.sql")):
        with conn.transaction():
            conn.execute(arquivo.read_text(encoding="utf-8"))
        print(f"ok: {arquivo.name}", flush=True)


def exportar_analytics(conn):
    SAIDAS.mkdir(parents=True, exist_ok=True)
    tabelas = [t for (t,) in conn.execute(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'analytics' ORDER BY 1")]
    for tabela in tabelas:
        cur = conn.execute(sql.SQL("SELECT * FROM {}").format(sql.Identifier("analytics", tabela)))
        destino = SAIDAS / f"{tabela}.csv"
        with open(destino, "w", encoding="utf-8-sig", newline="") as f:  # com BOM: o Power BI lê os acentos
            escritor = csv.writer(f)
            escritor.writerow([c.name for c in cur.description])
            escritor.writerows(cur)
        print(f"exportado: {destino.relative_to(RAIZ)} ({cur.rowcount} linhas)")


def mostrar_checagens(conn):
    falhas = 0
    for checagem, esperado, encontrado, ok in conn.execute(
            "SELECT checagem, esperado, encontrado, ok FROM analytics.checagens"):
        falhas += not ok
        print(f"{'OK   ' if ok else 'FALHA'} {checagem}: esperado {esperado}, encontrado {encontrado}")
    print("todas as checagens passaram" if not falhas else f"{falhas} checagem(ns) com falha")


def main():
    load_dotenv(RAIZ / ".env")  # o psycopg lê PGHOST, PGUSER... do ambiente
    with psycopg.connect(autocommit=True) as conn:
        rodar_sql(conn)
        exportar_analytics(conn)
        mostrar_checagens(conn)


if __name__ == "__main__":
    main()
