#!/bin/bash
set -e

BOOK_SLUG="essais-on-learning-vol1"
METADATA="metadata.yaml"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

# Step 1: Compile chapters in filename order
cat $METADATA chapters/*.md > "$OUTPUT_DIR/combined.md"

# Step 2: Strip draft notes sections
python3 - <<'PYEOF'
import re, pathlib

text = pathlib.Path("output/combined.md").read_text()

patterns = [
    r'(?m)^## Notes on the draft.*?(?=\n# |\n## (?!Notes)|\Z)',
    r'(?m)^## Notes on Draft.*?(?=\n# |\n## (?!Notes)|\Z)',
]
for pattern in patterns:
    text = re.sub(pattern, '', text, flags=re.DOTALL)

pathlib.Path("output/combined.md").write_text(text.strip() + "\n")
print("✓ Draft notes stripped")
PYEOF

# Step 3: Cover flag
COVER_FLAG=""
if [ -f "cover.jpg" ]; then
  COVER_FLAG="--epub-cover-image=cover.jpg"
else
  echo "Warning: cover.jpg not found — building without cover."
fi

# Step 4: EPUB
pandoc "$OUTPUT_DIR/combined.md" \
  --from markdown \
  --to epub3 \
  $COVER_FLAG \
  --css=styles/kindle.css \
  --mathml \
  --toc --toc-depth=2 \
  --output="$OUTPUT_DIR/$BOOK_SLUG.epub"

# Step 5: HTML (proofing)
pandoc "$OUTPUT_DIR/combined.md" \
  --from markdown \
  --to html5 \
  --standalone \
  --mathjax \
  --css=styles/kindle.css \
  --toc \
  --output="$OUTPUT_DIR/$BOOK_SLUG.html"

echo "Built: $OUTPUT_DIR/$BOOK_SLUG.epub"
echo "Built: $OUTPUT_DIR/$BOOK_SLUG.html"