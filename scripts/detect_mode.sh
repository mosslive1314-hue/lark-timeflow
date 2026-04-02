#!/bin/bash
# Detect whether to use local or remote mode
# Exit codes: 0=local, 1=remote, 2=no data available

LOCAL_DB="$HOME/Library/Application Support/Knowledge/knowledgeC.db"
ICLOUD_DB="$HOME/Library/Mobile Documents/com~apple~CloudDocs/knowledgeC_sync.db"

# Check local mode: does the local db have recent app/usage data (last 1 hour)?
if [ -f "$LOCAL_DB" ]; then
  LOCAL_COUNT=$(sqlite3 "$LOCAL_DB" "
    SELECT COUNT(*) FROM ZOBJECT 
    WHERE ZSTREAMNAME='/app/usage' 
    AND (ZOBJECT.ZENDDATE + 978307200) > (strftime('%s','now') - 3600);" 2>/dev/null)
  
  if [ "$LOCAL_COUNT" -gt "5" ] 2>/dev/null; then
    echo "local"
    echo "LOCAL_DB=$LOCAL_DB"
    exit 0
  fi
fi

# Check remote mode: does the iCloud synced db exist?
if [ -f "$ICLOUD_DB" ]; then
  echo "remote"
  echo "ICLOUD_DB=$ICLOUD_DB"
  exit 1
fi

echo "none"
exit 2
