#!/bin/bash

# Define variables
TARGET_FILE="prophet_paper_20170113.pdf"
EXPECTED_PATH="/docs/static/$TARGET_FILE"
SEARCH_DIR="./docs"
LOG_FILE="fix_jekyll_references.log"

# Start logging
echo "Fixing Jekyll References - $(date)" > $LOG_FILE

# Step 1: Search for invalid references
echo "Searching for invalid references to '$TARGET_FILE'..." | tee -a $LOG_FILE
INVALID_PATHS=$(grep -r "$TARGET_FILE" $SEARCH_DIR 2>/dev/null)

if [[ -z "$INVALID_PATHS" ]]; then
    echo "No invalid references found. Exiting..." | tee -a $LOG_FILE
    exit 0
fi

echo "Invalid references found:" | tee -a $LOG_FILE
echo "$INVALID_PATHS" | tee -a $LOG_FILE

# Step 2: Correct the paths
echo "Correcting invalid references to '$EXPECTED_PATH'..." | tee -a $LOG_FILE
while IFS= read -r line; do
    FILE=$(echo "$line" | cut -d: -f1)
    echo "Processing file: $FILE" | tee -a $LOG_FILE
    sed -i "s|/docs/docs/docs/static/$TARGET_FILE|$EXPECTED_PATH|g" "$FILE"
    sed -i "s|/docs/docs/static/$TARGET_FILE|$EXPECTED_PATH|g" "$FILE"
done <<< "$INVALID_PATHS"

# Step 3: Verify the changes
echo "Verifying changes..." | tee -a $LOG_FILE
grep -r "$TARGET_FILE" $SEARCH_DIR | tee -a $LOG_FILE

# Step 4: Restart Docker containers
echo "Restarting Docker containers..." | tee -a $LOG_FILE
docker-compose down >> $LOG_FILE 2>&1
docker-compose up -d >> $LOG_FILE 2>&1

echo "Fix completed. Please check the logs for details: $LOG_FILE"
