#!/bin/bash
set -e

WIKI_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="/tmp/ppc-code-ai-agent-wiki"
REMOTE_URL="https://github.com/larchanka/ppc-code-ai-agent.wiki.git"

echo "Checking if wiki repository exists on GitHub..."
if ! git ls-remote "$REMOTE_URL" > /dev/null 2>&1; then
  echo ""
  echo "The GitHub Wiki repository has not been initialized on GitHub yet."
  echo "GitHub creates the .wiki.git repository only after the first page is saved in the browser:"
  echo "  1. Open: https://github.com/larchanka/ppc-code-ai-agent/wiki"
  echo "  2. Click 'Create the first page' and click 'Save page'."
  echo "  3. Re-run: ./wiki/deploy.sh"
  exit 1
fi

rm -rf "$TEMP_DIR"
git clone "$REMOTE_URL" "$TEMP_DIR"

echo "Copying wiki pages..."
cp -R "$WIKI_DIR"/*.md "$TEMP_DIR/"

cd "$TEMP_DIR"
git add .
if git diff --staged --quiet; then
  echo "Wiki is already up to date!"
else
  git commit -m "docs(wiki): publish full wiki documentation"
  git push origin HEAD
  echo "Wiki deployed successfully!"
fi

rm -rf "$TEMP_DIR"
