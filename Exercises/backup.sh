#!/bin/bash
# backup.sh - Automated backup script
# Usage: ./backup.sh <source_dir> <backup_dir>

set -euo pipefail

# --- Configuration ---
MAX_BACKUPS=5
LOG_FILE="/var/log/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- Functions ---
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

die() {
    log_message "ERROR: $1"
    exit 1
}

# --- Argument validation ---
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_dir> <backup_dir>"
    exit 1
fi

SOURCE_DIR="$1"
BACKUP_DIR="$2"

[ -d "$SOURCE_DIR" ] || die "Source directory '$SOURCE_DIR' does not exist"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR" || die "Cannot create backup directory '$BACKUP_DIR'"

# --- Create the backup ---
ARCHIVE_NAME="backup_$(basename "$SOURCE_DIR")_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

log_message "Starting backup of '$SOURCE_DIR' to '$ARCHIVE_PATH'"

if tar czf "$ARCHIVE_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null; then
    ARCHIVE_SIZE=$(du -sh "$ARCHIVE_PATH" | cut -f1)
    log_message "Backup successful: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
else
    die "Backup failed for '$SOURCE_DIR'"
fi

# --- Rotate old backups ---
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    EXCESS=$((BACKUP_COUNT - MAX_BACKUPS))
    log_message "Rotating backups: removing $EXCESS old backup(s)"
    ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "$EXCESS" | while read -r old_backup; do
        rm -f "$old_backup"
        log_message "Deleted old backup: $(basename "$old_backup")"
    done
fi

# --- Summary ---
TOTAL_BACKUPS=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log_message "Backup complete. Total: $TOTAL_BACKUPS backup(s), $TOTAL_SIZE used"

echo ""
echo "=== Backup Summary ==="
echo "Archive: $ARCHIVE_PATH"
echo "Size: $ARCHIVE_SIZE"
echo "Total backups: $TOTAL_BACKUPS"
echo "Total space: $TOTAL_SIZE"