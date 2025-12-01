#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="${CONTENT_DIR:-content}"
OUTPUT_DIR="${OUTPUT_DIR:-static/downloads}"
DATA_DIR="data"
DOWNLOADS_DATA="${DATA_DIR}/downloads.json"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc não encontrado; instale-o antes de rodar este script." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado; instale-o antes de rodar este script." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$DATA_DIR"

# inicia arquivo de dados
echo "[]" > "$DOWNLOADS_DATA"

EXCLUDE_DIRS=("downloads" "sobre" "books")

for book_dir in "$CONTENT_DIR"/*; do
  [ -d "$book_dir" ] || continue
  book_name="$(basename "$book_dir")"
  [[ " ${EXCLUDE_DIRS[*]} " == *" ${book_name} "* ]] && continue
  metadata_file="$book_dir/_index.md"
  if [ ! -f "$metadata_file" ]; then
    echo "_index.md não encontrado em $book_name, pulando..."
    continue
  fi

  mapfile -t chapters < <(find "$book_dir" -maxdepth 1 -type f -name "*.md" ! -name "_index.md" | sort)
  if [ ${#chapters[@]} -eq 0 ]; then
    echo "Nenhum capítulo encontrado em $book_name, pulando..."
    continue
  fi

  # Metadados básicos
  book_title="$(grep -m1 '^title:' "$metadata_file" | sed 's/title:[[:space:]]*//; s/^"//; s/"$//' || true)"
  book_author="$(grep -m1 '^author:' "$metadata_file" | sed 's/author:[[:space:]]*//; s/^"//; s/"$//' || true)"
  book_lang="$(grep -m1 '^language:' "$metadata_file" | sed 's/language:[[:space:]]*//; s/^"//; s/"$//' || true)"

  echo "Gerando PDF e EPUB para $book_title ($book_name)..."
  pandoc "$metadata_file" "${chapters[@]}" \
    --toc --toc-depth=2 \
    --metadata-file="$metadata_file" \
    --metadata=title:"${book_title:-$book_name}" \
    --metadata=author:"${book_author:-}" \
    --metadata=lang:"${book_lang:-pt-BR}" \
    --resource-path=".:$book_dir:static" \
    --pdf-engine=xelatex \
    -V mainfont="TeX Gyre Pagella" \
    -V sansfont="TeX Gyre Heros" \
    -V monofont="DejaVu Sans Mono" \
    -V fontsize=12pt \
    -V linestretch=1.3 \
    -V geometry=margin=2.5cm \
    -o "$OUTPUT_DIR/$book_name.pdf"

  pandoc "$metadata_file" "${chapters[@]}" \
    --toc --toc-depth=2 \
    --metadata-file="$metadata_file" \
    --metadata=title:"${book_title:-$book_name}" \
    --metadata=author:"${book_author:-}" \
    --metadata=lang:"${book_lang:-pt-BR}" \
    --resource-path=".:$book_dir:static" \
    -o "$OUTPUT_DIR/$book_name.epub"

  generated_at="$(date -Is)"
  tmp="$(mktemp)"
  jq --arg slug "$book_name" --arg title "${book_title:-$book_name}" --arg generated_at "$generated_at" \
    '. += [{"slug":$slug,"title":$title,"generated_at":$generated_at}]' "$DOWNLOADS_DATA" > "$tmp"
  mv "$tmp" "$DOWNLOADS_DATA"
done

echo "Conversão concluída. Arquivos disponíveis em $OUTPUT_DIR"
