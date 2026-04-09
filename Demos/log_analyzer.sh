#!/bin/bash
# log_analyzer.sh - Analyze web server access logs
# Usage: ./log_analyzer.sh <log_file>

set -euo pipefail

# --- Argument validation ---
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found"
    exit 1
fi

TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")

STATUS_200=$(grep -c '" 200 ' "$LOG_FILE" || true)
STATUS_301=$(grep -c '" 301 ' "$LOG_FILE" || true)
STATUS_403=$(grep -c '" 403 ' "$LOG_FILE" || true)
STATUS_404=$(grep -c '" 404 ' "$LOG_FILE" || true)
STATUS_500=$(grep -c '" 500 ' "$LOG_FILE" || true)

printf "  200 OK:            %5d (%d%%)\n" "$STATUS_200" "$((STATUS_200 * 100 / TOTAL_REQUESTS))"
printf "  301 Redirect:      %5d (%d%%)\n" "$STATUS_301" "$((STATUS_301 * 100 / TOTAL_REQUESTS))"
printf "  403 Forbidden:     %5d (%d%%)\n" "$STATUS_403" "$((STATUS_403 * 100 / TOTAL_REQUESTS))"
printf "  404 Not Found:     %5d (%d%%)\n" "$STATUS_404" "$((STATUS_404 * 100 / TOTAL_REQUESTS))"
printf "  500 Server Error:  %5d (%d%%)\n" "$STATUS_500" "$((STATUS_500 * 100 / TOTAL_REQUESTS))"
echo ""

ERRORS_4XX=$(grep -c '" 4[0-9][0-9] ' "$LOG_FILE" || true)
ERRORS_5XX=$(grep -c '" 5[0-9][0-9] ' "$LOG_FILE" || true)
echo "  Total client errors (4xx): $ERRORS_4XX"
echo "  Total server errors (5xx): $ERRORS_5XX"
echo ""

echo "--- Top 5 Most Requested Paths ---"
echo ""
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -5 | while read -r count path; do
    printf "  %5d requests  %s\n" "$count" "$path"
done
echo ""