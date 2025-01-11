#!/bin/bash

# Define the path to the SCSS file
SCSS_FILE="docs/css/main.scss"

# Check if the SCSS file exists
if [ ! -f "$SCSS_FILE" ]; then
  echo "Error: SCSS file not found at $SCSS_FILE."
  exit 1
fi

echo "Checking $SCSS_FILE for errors..."

# Backup the original SCSS file
BACKUP_FILE="${SCSS_FILE}.backup"
cp "$SCSS_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Use sed to fix invalid properties ending with ': ;' or ';'
# Assuming properties must have values, replace invalid lines with comments
sed -i.bak -E 's/([a-zA-Z\-]+):[ \t]*;/\/* \1: <missing-value>; Fixed by script *\//g' "$SCSS_FILE"

# Check if the file was modified
if diff "$SCSS_FILE" "$BACKUP_FILE" > /dev/null; then
  echo "No errors detected in $SCSS_FILE."
else
  echo "Errors found and fixed in $SCSS_FILE:"
  diff "$SCSS_FILE" "$BACKUP_FILE"
fi

# Clean up temporary backup file created by sed
rm -f "${SCSS_FILE}.bak"

# Prompt to rebuild the Jekyll site
read -p "Do you want to rebuild the Jekyll site now? (y/n): " REBUILD
if [[ "$REBUILD" == "y" || "$REBUILD" == "Y" ]]; then
  echo "Rebuilding the Jekyll site using Docker Compose..."
  docker-compose up --build
else
  echo "Skipping rebuild. Please rebuild the site manually when ready."
fi

echo "Done."
