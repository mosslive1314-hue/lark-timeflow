#!/bin/bash
# Collect app usage and Chrome history data for a given date
# Usage: collect.sh [YYYY-MM-DD]  (defaults to today)

set -e

DATE="${1:-$(date +%Y-%m-%d)}"
OUTDIR="/tmp/time_mirror"
mkdir -p "$OUTDIR"

LOCAL_KC="$HOME/Library/Application Support/Knowledge/knowledgeC.db"
ICLOUD_KC="$HOME/Library/Mobile Documents/com~apple~CloudDocs/knowledgeC_sync.db"
LOCAL_CHROME="$HOME/Library/Application Support/Google/Chrome/Default/History"
ICLOUD_CHROME="$HOME/Library/Mobile Documents/com~apple~CloudDocs/chrome_history_sync.db"

TMP_KC="$OUTDIR/knowledgeC_tmp.db"
TMP_CHROME="$OUTDIR/chrome_tmp.db"
RAW_OUT="$OUTDIR/raw_${DATE}.json"

echo "📅 Collecting data for: $DATE"

# --- Step 1: Determine mode and copy knowledgeC ---
MODE=$("$(dirname "$0")/detect_mode.sh" | head -1)
echo "🔍 Mode: $MODE"

if [ "$MODE" = "local" ]; then
  cp "$LOCAL_KC" "$TMP_KC" 2>/dev/null || true
  # Also copy WAL/SHM for complete data
  cp "${LOCAL_KC}-wal" "${TMP_KC}-wal" 2>/dev/null || true
  cp "${LOCAL_KC}-shm" "${TMP_KC}-shm" 2>/dev/null || true
elif [ "$MODE" = "remote" ]; then
  brctl download "$ICLOUD_KC" 2>/dev/null || true
  sleep 2
  dd if="$ICLOUD_KC" of="$TMP_KC" bs=4096 2>/dev/null
else
  echo "❌ No knowledgeC data available"
  exit 1
fi

# --- Step 2: Copy Chrome History ---
if [ "$MODE" = "local" ] && [ -f "$LOCAL_CHROME" ]; then
  cp "$LOCAL_CHROME" "$TMP_CHROME" 2>/dev/null || true
elif [ -f "$ICLOUD_CHROME" ]; then
  brctl download "$ICLOUD_CHROME" 2>/dev/null || true
  sleep 2
  dd if="$ICLOUD_CHROME" of="$TMP_CHROME" bs=4096 2>/dev/null
fi

# --- Step 3: Extract app usage ---
echo "📊 Extracting app usage..."
APP_USAGE=$(sqlite3 "$TMP_KC" "
SELECT json_group_array(json_object(
  'app', ZVALUESTRING,
  'start', datetime(ZSTARTDATE+978307200,'unixepoch','localtime'),
  'end', datetime(ZENDDATE+978307200,'unixepoch','localtime'),
  'minutes', CAST((ZENDDATE - ZSTARTDATE)/60.0 AS INTEGER)
))
FROM ZOBJECT 
WHERE ZSTREAMNAME='/app/usage' 
  AND datetime(ZSTARTDATE+978307200,'unixepoch','localtime') BETWEEN '${DATE} 00:00:00' AND '${DATE} 23:59:59'
  AND (ZENDDATE - ZSTARTDATE) > 30
ORDER BY ZSTARTDATE ASC;" 2>/dev/null || echo "[]")

# --- Step 4: Extract Chrome history ---
CHROME_HISTORY="[]"
if [ -f "$TMP_CHROME" ]; then
  echo "🌐 Extracting Chrome history..."
  CHROME_HISTORY=$(sqlite3 "$TMP_CHROME" "
  SELECT json_group_array(json_object(
    'url', u.url,
    'title', u.title,
    'visit_time', datetime(v.visit_time/1000000-11644473600,'unixepoch','localtime')
  ))
  FROM visits v JOIN urls u ON v.url = u.id
  WHERE datetime(v.visit_time/1000000-11644473600,'unixepoch','localtime') BETWEEN '${DATE} 00:00:00' AND '${DATE} 23:59:59'
  ORDER BY v.visit_time ASC;" 2>/dev/null || echo "[]")
fi

# --- Step 5: Write output ---
cat > "$RAW_OUT" << EOF
{
  "date": "$DATE",
  "mode": "$MODE",
  "app_usage": $APP_USAGE,
  "chrome_history": $CHROME_HISTORY
}
EOF

echo "✅ Data collected → $RAW_OUT"

# --- Cleanup ---
rm -f "$TMP_KC" "${TMP_KC}-wal" "${TMP_KC}-shm" "$TMP_CHROME" 2>/dev/null || true
