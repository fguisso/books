#!/usr/bin/env bash
set -euo pipefail

# Serve site gerado com Hugo (HTML) + PDFs/EPUBs gerados pelo Pandoc.
# Requer: hugo extended, pandoc, python3.

PORT="${PORT:-1313}"
DOWNLOAD_PORT="${DOWNLOAD_PORT:-1314}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-static/downloads}"
# Define BASEURL automaticamente com o IP local ao usar 0.0.0.0; pode ser sobrescrito.
if [ -z "${BASEURL:-}" ]; then
  HOST_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
  if [ -n "${HOST_IP:-}" ]; then
    BASEURL="http://${HOST_IP}:${PORT}"
  else
    BASEURL="http://localhost:${PORT}"
  fi
fi

if ! command -v go >/dev/null 2>&1; then
  if [ -x /usr/local/go/bin/go ]; then
    export PATH="/usr/local/go/bin:$PATH"
    echo "go encontrado em /usr/local/go/bin e adicionado ao PATH."
  else
    echo "go não encontrado. Instale Go >= 1.21." >&2
    exit 1
  fi
fi

command -v hugo >/dev/null 2>&1 || { echo "hugo não encontrado. Instale Hugo Extended."; exit 1; }
command -v pandoc >/dev/null 2>&1 || { echo "pandoc não encontrado. Instale pandoc + LaTeX."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 não encontrado."; exit 1; }

mkdir -p "${DOWNLOAD_DIR}"

echo "1/3 Atualizando módulos do Hugo (tema Hextra)..."
hugo mod tidy

echo "2/3 Gerando PDFs/EPUBs em ${DOWNLOAD_DIR} (servirá em /downloads)..."
OUTPUT_DIR="${DOWNLOAD_DIR}" ./scripts/pandoc-build.sh

echo "Servindo downloads em http://localhost:${DOWNLOAD_PORT}"
python3 -m http.server "${DOWNLOAD_PORT}" -d "${DOWNLOAD_DIR}" &
DOWNLOAD_PID=$!
trap "kill ${DOWNLOAD_PID} >/dev/null 2>&1 || true" EXIT

echo "3/3 Iniciando Hugo server em ${BASEURL} (CTRL+C para sair)..."
hugo server -D --buildFuture --baseURL "${BASEURL}" --port "${PORT}" --bind "0.0.0.0" --disableFastRender
