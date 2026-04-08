# TP 2: Fundamental Shell Scripting

| | |
|---|---|
| **Estimated Duration** | 1h30 |
| **Objectives** | Write practical bash scripts: backup, user creation from CSV, log analyzer with grep/awk/sed |
| **Prerequisites** | See below |
| **Difficulty** | Intermediate to Advanced |

### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for full system access)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended)
- Install via VirtualBox, UTM (macOS), VMware, or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk
- Snapshot your VM before each lab

**Option B -- Docker Container**
- Docker Desktop installed and running
- Pull required images: `docker pull ubuntu:22.04`
- Both options work equally well for this lab

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` commands and run the Linux commands directly in your VM terminal.

---

## Scenario

You are a junior sysadmin tasked with automating repetitive tasks. You will write three scripts, each building on the skills learned in the previous one.

---

## Setup

```bash
docker run -it --rm --hostname scripting-lab --name tp2 ubuntu:22.04 bash
apt update && apt install -y vim tree gawk
```

---

## Exercise A: Backup Script (30 min)

### Objective

Write a script `backup.sh` that:
1. Takes a source directory and a destination directory as arguments
2. Creates a timestamped tar.gz archive of the source
3. Keeps only the last 5 backups (deletes older ones)
4. Logs all operations to a log file
5. Handles errors gracefully

### Step 1: Basic Structure

Create the file `/root/scripts/backup.sh`:

```bash
mkdir -p /root/scripts
```

Start with this skeleton:

```bash
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

# --- Argument validation ---
# TODO: Check that exactly 2 arguments are provided
# TODO: Check that the source directory exists
# TODO: Check that the backup directory exists (or create it)

# --- Create the backup ---
# TODO: Create the tar.gz archive with a timestamped name
# TODO: Log success or failure

# --- Rotate old backups ---
# TODO: Count backups, delete oldest if more than MAX_BACKUPS

# --- Summary ---
# TODO: Display backup size and total backup count
```

### Step 2: Implement the Script

Complete all the TODO sections. Your script should:
- Validate that exactly 2 arguments are passed (use `$#`)
- Check that the source directory exists (use `[ -d "$1" ]`)
- Create the backup directory if it doesn't exist
- Create a `tar.gz` archive with a timestamped filename
- List backups sorted by time and remove the oldest ones when there are more than `MAX_BACKUPS`
- Display a summary with the archive size and total backup count

### Step 3: Test It

```bash
chmod +x /root/scripts/backup.sh

# Create test data
mkdir -p /tmp/myproject/{src,docs,config}
echo "main code" > /tmp/myproject/src/main.py
echo "documentation" > /tmp/myproject/docs/README.md
echo "config data" > /tmp/myproject/config/app.yml

# Run the backup
/root/scripts/backup.sh /tmp/myproject /tmp/backups

# Run it multiple times to test rotation
for i in $(seq 1 6); do
    sleep 1
    /root/scripts/backup.sh /tmp/myproject /tmp/backups
done

# Check that only 5 backups remain
ls -lt /tmp/backups/

# Check the log
cat /var/log/backup.log
```

---

## Exercise B: User Creation from CSV (30 min)

### Objective

Write a script `create_users.sh` that:
1. Reads a CSV file containing user information
2. Creates each user with the specified properties
3. Creates groups if they don't exist
4. Sets initial passwords
5. Generates a report of actions taken

### Step 1: Create the CSV File

```bash
cat > /root/scripts/users.csv << 'EOF'
username,fullname,group,shell
alice,Alice Martin,developers,/bin/bash
bob,Bob Johnson,developers,/bin/bash
charlie,Charlie Brown,operations,/bin/bash
david,David Wilson,operations,/bin/bash
eve,Eve Davis,management,/bin/bash
frank,Frank Miller,management,/bin/bash
grace,Grace Lee,developers,/bin/bash
EOF
```

### Step 2: Write the Script

Create `/root/scripts/create_users.sh`:

```bash
#!/bin/bash
# create_users.sh - Create users from a CSV file
# Usage: ./create_users.sh <csv_file>

set -euo pipefail

# TODO: Validate arguments (CSV file exists)
# TODO: Skip the header line
# TODO: For each line:
#   - Parse username, fullname, group, shell
#   - Create the group if it doesn't exist
#   - Create the user with the specified options
#   - Set a default password (username + "2024")
#   - Log what was done
# TODO: Generate a summary report
```

Complete the script. Key techniques to use:
- `IFS=',' read -r field1 field2 ...` to parse CSV fields
- `tail -n +2` to skip the header line
- `getent group NAME` to check if a group exists
- `id USER 2>/dev/null` to check if a user exists
- The script should be **idempotent** (safe to run multiple times without errors)

### Step 3: Test It

```bash
chmod +x /root/scripts/create_users.sh

# Run the script
/root/scripts/create_users.sh /root/scripts/users.csv

# Verify users were created
for user in alice bob charlie david eve frank grace; do
    id $user
done

# Run again to verify idempotency (users should be skipped)
/root/scripts/create_users.sh /root/scripts/users.csv
```

---

## Exercise C: Log Analyzer with grep/awk/sed (30 min)

### Objective

Write a script `log_analyzer.sh` that:
1. Generates a sample log file (simulating a web server)
2. Analyzes the log to extract statistics
3. Uses grep, awk, and sed for text processing
4. Outputs a formatted report

### Step 1: Generate Sample Logs

```bash
cat > /root/scripts/generate_logs.sh << 'SCRIPT'
#!/bin/bash
# Generate realistic-looking web server logs

LOG_FILE="/tmp/access.log"
> "$LOG_FILE"  # Clear the file

IPS=("192.168.1.10" "192.168.1.25" "10.0.0.5" "172.16.0.100" "192.168.1.10" "10.0.0.5" "192.168.1.10")
METHODS=("GET" "POST" "GET" "GET" "PUT" "DELETE" "GET" "GET" "GET" "POST")
PATHS=("/index.html" "/api/users" "/images/logo.png" "/api/products" "/css/style.css" "/api/users/1" "/about.html" "/api/login" "/api/search?q=test" "/favicon.ico")
CODES=("200" "200" "200" "301" "404" "500" "200" "403" "200" "200" "404" "500" "200" "200")

for i in $(seq 1 200); do
    IP=${IPS[$((RANDOM % ${#IPS[@]}))]}
    METHOD=${METHODS[$((RANDOM % ${#METHODS[@]}))]}
    PATH_=${PATHS[$((RANDOM % ${#PATHS[@]}))]}
    CODE=${CODES[$((RANDOM % ${#CODES[@]}))]}
    SIZE=$((RANDOM % 50000 + 100))
    HOUR=$((RANDOM % 24))
    MIN=$((RANDOM % 60))
    SEC=$((RANDOM % 60))
    printf '%s - - [05/Apr/2026:%02d:%02d:%02d +0000] "%s %s HTTP/1.1" %s %d\n' \
        "$IP" "$HOUR" "$MIN" "$SEC" "$METHOD" "$PATH_" "$CODE" "$SIZE" >> "$LOG_FILE"
done

echo "Generated $(wc -l < "$LOG_FILE") log entries in $LOG_FILE"
SCRIPT

chmod +x /root/scripts/generate_logs.sh
/root/scripts/generate_logs.sh
```

### Step 2: Write the Log Analyzer

Create `/root/scripts/log_analyzer.sh`:

```bash
#!/bin/bash
# log_analyzer.sh - Analyze web server access logs
# Usage: ./log_analyzer.sh <log_file>

# TODO: Validate arguments
# TODO: Use grep to count errors (4xx, 5xx)
# TODO: Use awk to extract and count unique IPs
# TODO: Use awk to calculate total bytes transferred
# TODO: Use sed to extract and format timestamps
# TODO: Find the top 5 most requested paths
# TODO: Find the top 3 most active IPs
# TODO: Count requests per HTTP method
# TODO: Generate a formatted report
```

Your report should include:
- HTTP status code breakdown (200, 301, 403, 404, 500 counts with percentages)
- Total client errors (4xx) and server errors (5xx)
- Top 5 most requested paths
- Top 5 most active IP addresses
- Requests per HTTP method
- Total bandwidth transferred
- Number of unique visitors
- Busiest hours

### Step 3: Test It

```bash
chmod +x /root/scripts/log_analyzer.sh

# Install bc for bandwidth calculation
apt install -y bc

# Run the analyzer
/root/scripts/log_analyzer.sh /tmp/access.log

# Test with grep to find specific patterns
echo ""
echo "=== Manual grep exercises ==="
echo ""

# Find all 404 errors
echo "All 404 errors:"
grep '" 404 ' /tmp/access.log | head -5
echo ""

# Find all requests from a specific IP
echo "Requests from 192.168.1.10:"
grep "^192.168.1.10" /tmp/access.log | head -5
echo ""

# Find all POST requests
echo "POST requests:"
grep '"POST' /tmp/access.log | head -5
```

---

## Verification

Final checklist:

- [ ] `backup.sh` creates timestamped archives and rotates old ones
- [ ] `backup.sh` handles errors (missing arguments, non-existent directories)
- [ ] `create_users.sh` parses CSV correctly (skipping header)
- [ ] `create_users.sh` creates groups and users with correct properties
- [ ] `create_users.sh` is idempotent (safe to run twice)
- [ ] `log_analyzer.sh` uses grep, awk, and sed effectively
- [ ] `log_analyzer.sh` produces a readable, formatted report
- [ ] All scripts use `set -euo pipefail` for safety
- [ ] All scripts validate their arguments

---

## Grading Criteria

| Criterion | Points |
|---|---|
| **backup.sh** | |
| Argument validation and error handling | 2 |
| Archive creation with timestamp | 2 |
| Backup rotation (keep last N) | 2 |
| Logging to file | 1 |
| **create_users.sh** | |
| CSV parsing (skip header, handle fields) | 2 |
| Group creation (idempotent) | 1 |
| User creation with correct options | 2 |
| Password setting and report generation | 1 |
| **log_analyzer.sh** | |
| Uses grep effectively | 1 |
| Uses awk for field extraction and aggregation | 2 |
| Uses sed for pattern extraction | 1 |
| Formatted output | 1 |
| **Bonus** | |
| Clean code with comments | +1 |
| Additional features (email notification, color output) | +1 |
| **Total** | **18 (+2 bonus)** |

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| Missing quotes around variables | `$VAR` should be `"$VAR"` to handle spaces in filenames |
| Not checking exit codes | Always check if commands succeed before continuing |
| Using `cat file \| grep` | Useless use of cat; use `grep pattern file` directly |
| Forgetting `#!/bin/bash` | Without the shebang, the script may run in `sh` instead of `bash` |
| Not making the script executable | Always `chmod +x` before running |
| `set -e` with pipes | In a pipeline, only the last command's exit code matters by default; use `set -o pipefail` |

> Solutions are available from your trainer.
