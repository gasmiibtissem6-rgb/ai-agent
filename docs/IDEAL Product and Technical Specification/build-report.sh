#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

JOB_NAME="IDEAL_Product_and_Technical_Specification"
ENTRYPOINT="main.tex"
PDF_NAME="${JOB_NAME}.pdf"

cleanup_auxiliary_files() {
  rm -f \
    ./*.aux \
    ./*.bbl \
    ./*.blg \
    ./*.fdb_latexmk \
    ./*.fls \
    ./*.lof \
    ./*.log \
    ./*.lot \
    ./*.out \
    ./*.synctex.gz \
    ./*.toc
  rm -f \
    ./acronyms.pdf \
    ./commands.pdf \
    ./main.pdf \
    ./preamble.pdf \
    ./title_page.pdf
}

cleanup_auxiliary_files

echo "Building ${PDF_NAME} from ${ENTRYPOINT}..."

if command -v latexmk >/dev/null 2>&1; then
  latexmk \
    -pdf \
    -interaction=nonstopmode \
    -halt-on-error \
    -jobname="${JOB_NAME}" \
    "${ENTRYPOINT}"
else
  pdflatex -interaction=nonstopmode -halt-on-error -jobname="${JOB_NAME}" "${ENTRYPOINT}"
  pdflatex -interaction=nonstopmode -halt-on-error -jobname="${JOB_NAME}" "${ENTRYPOINT}"
fi

cleanup_auxiliary_files

echo "Build complete: ${PDF_NAME}"
echo "Auxiliary LaTeX files removed."
