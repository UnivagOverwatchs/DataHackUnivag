"""Leitura das tabelas de analytics para o dashboard: pela API da equipe ou pelos CSV exportados.

A API (repositório api_dataHack) responde em GET /data?schema=...&table=...&limit=... com
{"schema", "table", "count", "data": [linhas]}. Se ela não responder, o dashboard usa os CSV
de src/outputs/, que são a exportação da mesma camada analytics.
"""
import csv
import json
from pathlib import Path
from urllib import parse, request

SAIDAS = Path(__file__).resolve().parents[1] / "src" / "outputs"
LIMITE = 1000  # máximo aceito pela API; ela não tem paginação


def _texto(valor):
    """Deixa o valor da API igual ao do CSV: vazio para nulo, True/False, número sem '.0' sobrando."""
    if valor is None:
        return ""
    if isinstance(valor, bool):
        return "True" if valor else "False"
    if isinstance(valor, float) and valor.is_integer():
        return str(int(valor))
    return str(valor)


def ler_api(nome, api, schema="analytics", tempo=20):
    consulta = parse.urlencode({"schema": schema, "table": nome, "limit": LIMITE})
    with request.urlopen(f"{api.rstrip('/')}/data?{consulta}", timeout=tempo) as resposta:
        corpo = json.loads(resposta.read().decode("utf-8"))
    return [{coluna: _texto(valor) for coluna, valor in linha.items()} for linha in corpo["data"]]


def ler_csv(nome):
    with open(SAIDAS / f"{nome}.csv", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def ler_tabela(nome, api=None):
    """Devolve (linhas, fonte). Tenta a API quando informada; se falhar, cai para o CSV."""
    if api:
        try:
            return ler_api(nome, api), "API"
        except Exception as erro:  # API fora do ar, rede bloqueada, tabela ausente
            print(f"  aviso: API não respondeu para {nome} ({type(erro).__name__}); usando o CSV")
    return ler_csv(nome), "CSV"
