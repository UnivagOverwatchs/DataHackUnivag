"""Serve o dashboard Rota do Diploma por HTTP (FastAPI).

Uso:  uvicorn src.painel.main:app --host 0.0.0.0 --port 8080     (de dentro de Sentinela/)
Ou pela imagem Docker: ver Dockerfile e docker-compose.yml em Sentinela/.

A página já leva os dados embutidos (gerada por src/06_prototipo_dashboard.py), então este
serviço não acessa o banco: só entrega o arquivo e o plano B em PDF.
"""
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse

PASTA = Path(__file__).resolve().parents[1] / "dashboard"
PAGINA = PASTA / "prototipo.html"
PLANO_B = PASTA / "plano_b_dashboard.pdf"

app = FastAPI(title="Rota do Diploma — dashboard", version="1.0.0",
              description="Entrega o dashboard da equipe Sentinela e o plano B em PDF.")


@app.get("/", include_in_schema=False)
def painel() -> FileResponse:
    if not PAGINA.exists():
        raise HTTPException(status_code=503, detail="Dashboard ainda não gerado: rode src/06_prototipo_dashboard.py")
    # sem cache: depois de gerar o painel de novo, o navegador pega a versão nova
    return FileResponse(PAGINA, media_type="text/html", headers={"Cache-Control": "no-store"})


@app.get("/plano-b", summary="Plano B em PDF, com as telas do dashboard")
def plano_b() -> FileResponse:
    if not PLANO_B.exists():
        raise HTTPException(status_code=404, detail="Plano B não encontrado")
    return FileResponse(PLANO_B, media_type="application/pdf", filename="rota_do_diploma_plano_b.pdf")


@app.get("/health", summary="Confere se o serviço está no ar e quando o dashboard foi gerado")
def health() -> dict:
    return {"status": "ok", "dashboard": PAGINA.exists(),
            "gerado_em": PAGINA.stat().st_mtime if PAGINA.exists() else None}
