# Biblioteca Hugo + Hextra + Pandoc

Site estático para múltiplos livros em pastas separadas, usando Hugo com o tema Hextra. O pipeline também gera PDF e EPUB via Pandoc/LaTeX e publica tudo no GitHub Pages.

## Pré-requisitos locais
- Hugo Extended (>= 0.124).
- Go (para baixar o tema via módulos).
- Pandoc e LaTeX (`texlive-latex-recommended`, `texlive-latex-extra`, `texlive-fonts-recommended`, `texlive-xetex`) para gerar PDF/EPUB localmente.
- `jq` (para o script escrever `data/downloads.json`).

## Estrutura
- `config/_default/`: configs do Hugo (tema, parâmetros, menus, módulos).
- `content/<livro>/`: cada livro em uma pasta de nível superior; `_index.md` guarda metadados e arquivos `NN-capitulo.md` formam os capítulos.
- `content/books/_index.md`: lista de livros (links para cada `/livro.../`).
- `static/downloads/`: pasta onde os PDFs/EPUBs são publicados (mantida por `.gitkeep`).
- `scripts/pandoc-build.sh`: concatena `_index.md` + capítulos e gera PDF/EPUB (padrão `static/downloads/`) e `data/downloads.json`.
- `.github/workflows/gh-pages.yml`: build + deploy no GitHub Pages.

## Configuração inicial
1) Ajuste `repoURL` e links de edição em `config/_default/params.toml` (o `baseURL` é passado automaticamente pelo workflow do GitHub Pages; altere só se for testar builds manuais com outro domínio).
2) Inicie os módulos do Hugo para trazer o tema:
```bash
hugo mod get
```

## Desenvolvimento
```bash
hugo server -D
```
Os livros ficam em `/books`; adicione capítulos numerados para preservar a ordem no Pandoc.

## Build/serve local com PDFs/EPUBs
- Ambiente de desenvolvimento (dois processos: Hugo server em `:1313` + servidor de downloads em `:1314`, PDFs/EPUBs gerados em `static/downloads`):
```bash
./scripts/dev.sh
```
  - Variáveis úteis: `PORT` (Hugo, padrão 1313), `DOWNLOAD_PORT` (downloads, padrão 1314), `DOWNLOAD_DIR` (saída dos arquivos, padrão `static/downloads`), `BASEURL` (auto: IP local + porta; defina manualmente se preferir).
- Somente build (sem servidor, gerando saída final em `public/` e downloads em `public/downloads/`):
```bash
OUTPUT_DIR=static/downloads ./scripts/pandoc-build.sh   # PDFs/EPUBs + data/downloads.json
hugo --minify
```

## GitHub Actions / Pages
O workflow `gh-pages.yml`:
1. Faz checkout.
2. Instala Hugo Extended.
3. Instala Pandoc + LaTeX.
4. Resolve módulos do Hugo (trazendo o tema Hextra).
5. Configura o Pages e calcula o `base_url` correto (incluindo subpath do repositório).
6. Gera o site (`public/`) usando `--baseURL` vindo do Pages (funciona em `<user>.github.io/<repo>` e em `<user>.github.io`).
7. Converte livros para PDF e EPUB (`public/downloads/`).
8. Publica em GitHub Pages.

Habilite GitHub Pages em `Settings > Pages` apontando para o artefato do workflow.
