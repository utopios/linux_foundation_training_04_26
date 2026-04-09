#!/bin/bash
# create_users.sh - Create users from a CSV file
# Usage: ./create_users.sh <csv_file>

set -euo pipefail

# --- Configuration ---
DEFAULT_PASSWORD_SUFFIX="2024"
REPORT_FILE="user_creation_report.txt"
CREATED_USERS=0
SKIPPED_USERS=0
CREATED_GROUPS=0

# --- Argument validation ---
if [ $# -ne 1 ]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

CSV_FILE="$1"

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file '$CSV_FILE' not found"
    exit 1
fi

# --- Initialize report ---
echo "=== User Creation Report ===" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "Source: $CSV_FILE" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"

# --- Process each line ---
tail -n +2 "$CSV_FILE" | while IFS=',' read -r username fullname group shell; do
    # Trim whitespace
    username=$(echo "$username" | tr -d ' ')
    fullname=$(echo "$fullname" | xargs)
    group=$(echo "$group" | tr -d ' ')
    shell=$(echo "$shell" | tr -d ' ')

    echo ""
    echo "Processing: $username ($fullname)"

    # Create group if it doesn't exist
    if ! getent group "$group" > /dev/null 2>&1; then
        groupadd "$group"
        echo "  [+] Created group: $group"
        echo "GROUP CREATED: $group" >> "$REPORT_FILE"
    else
        echo "  [=] Group already exists: $group"
    fi

    # Create user if they don't exist
    if id "$username" > /dev/null 2>&1; then
        echo "  [=] User already exists: $username (SKIPPED)"
        echo "USER SKIPPED: $username (already exists)" >> "$REPORT_FILE"
    else
        useradd -m -s "$shell" -g "$group" -c "$fullname" "$username"
        echo "${username}:${username}${DEFAULT_PASSWORD_SUFFIX}" | chpasswd
        echo "  [+] Created user: $username"
        echo "  [+] Set password: ${username}${DEFAULT_PASSWORD_SUFFIX}"
        echo "  [+] Home: /home/$username"
        echo "USER CREATED: $username | Group: $group | Shell: $shell" >> "$REPORT_FILE"
    fi
done

# --- Final report ---
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "Processing complete at $(date)" >> "$REPORT_FILE"

echo ""
echo "==============================="
echo "  User Creation Complete"
echo "==============================="
echo ""
echo "Report saved to: $REPORT_FILE"
cat "$REPORT_FILE"
echo ""

# Verify
echo "=== Verification ==="
echo "Users created:"
tail -n +2 "$CSV_FILE" | while IFS=',' read -r username rest; do
    username=$(echo "$username" | tr -d ' ')
    if id "$username" > /dev/null 2>&1; then
        echo "  $(id "$username")"
    fi
done