# Imagem do dashboard Rota do Diploma: FastAPI entregando a página com os dados embutidos.
#   docker build -t sentinela-dashboard .
#   docker run -d -p 8080:8080 --name sentinela-dashboard sentinela-dashboard
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir "fastapi==0.115.0" "uvicorn[standard]==0.30.6"

COPY src/painel ./src/painel
COPY src/dashboard ./src/dashboard

EXPOSE 8080

CMD ["uvicorn", "src.painel.main:app", "--host", "0.0.0.0", "--port", "8080"]
