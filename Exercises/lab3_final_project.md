# TP 3: Final Project - System Monitoring Script

| | |
|---|---|
| **Estimated Duration** | 1h30 |
| **Objectives** | Write a comprehensive system health check script covering CPU, memory, disk, network, logs, with HTML report generation and cron scheduling |
| **Prerequisites** | See below |


### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for the most complete experience)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended)
- Install via VirtualBox, UTM (macOS), VMware, or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk
- Snapshot your VM before each lab
- Note: A VM is **strongly recommended** for this final project. It provides real CPU/memory metrics, real disk partitions, real network interfaces, systemd, cron, and syslog -- all of which are used in the monitoring script. Containers have limited access to these system-level features

**Option B -- Docker Container**
- Docker Desktop installed and running
- Pull required images: `docker pull ubuntu:22.04`
- Note: Some exercises requiring systemd, cron daemon, kernel modules, or real system metrics (CPU, memory) are limited in containers. Metrics may reflect the host rather than the container

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` commands and run the Linux commands directly in your VM terminal.

---

## Scenario

You are the lead sysadmin for a small company. Management wants a daily system health report delivered as an HTML file. The report must cover:

1. CPU and memory usage
2. Disk space on all partitions
3. Network connectivity to key services
4. Analysis of recent error logs
5. Running services status
6. An overall health score

You will build this incrementally, testing each module before combining them.

---

## Setup

```bash
docker run -it --rm --hostname monitor-lab --name tp3 \
  -v /tmp/tp3_output:/output \
  ubuntu:22.04 bash
```

Install all required tools:

```bash
apt update && apt install -y \
  procps sysstat iproute2 iputils-ping \
  dnsutils curl bc cron vim tree net-tools
```

Create the working directory:

```bash
mkdir -p /root/monitoring
mkdir -p /var/log/monitoring
mkdir -p /output
```

---

## Part A: System Information Module (15 min)

### Objective

Write a function that collects basic system information.

Create `/root/monitoring/monitor.sh` and start building:

```bash
#!/bin/bash
# monitor.sh - System Health Check Script
# Author: [Your Name]
# Date: [Today]

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================
REPORT_DIR="/output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/health_report_${TIMESTAMP}.html"
LOG_FILE="/var/log/monitoring/monitor.log"

# Thresholds
CPU_WARN=70
CPU_CRIT=90
MEM_WARN=70
MEM_CRIT=90
DISK_WARN=70
DISK_CRIT=90

# Services to check (hosts and ports)
declare -A SERVICES
SERVICES[Google_DNS]="8.8.8.8"
SERVICES[Cloudflare_DNS]="1.1.1.1"

# ============================================
# LOGGING
# ============================================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# ============================================
# MODULE 1: SYSTEM INFO
# ============================================
get_system_info() {
    echo "hostname=$(hostname)"
    echo "kernel=$(uname -r)"
    echo "os=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "uptime=$(uptime -p 2>/dev/null || uptime)"
    echo "date=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "users=$(who 2>/dev/null | wc -l)"
}
```

**Test it:**

```bash
chmod +x /root/monitoring/monitor.sh
source /root/monitoring/monitor.sh
get_system_info
```

---

## Part B: CPU and Memory Module (15 min)

Add these functions to your script. Replace the TODO comments with working code.

```bash
# ============================================
# MODULE 2: CPU USAGE
# ============================================
get_cpu_usage() {
    # TODO: Calculate CPU usage
    # Use: top -bn1 | grep "Cpu(s)" or /proc/stat
    # Return: a percentage value
    # Also compare against CPU_WARN and CPU_CRIT thresholds
    # Output: cpu_percent=XX and cpu_status=OK|WARNING|CRITICAL
    echo "IMPLEMENT ME"
}

# ============================================
# MODULE 3: MEMORY USAGE
# ============================================
get_memory_info() {
    # TODO: Get memory stats
    # Use: free -m
    # Return: total, used, free, percentage
    # Also compare against MEM_WARN and MEM_CRIT thresholds
    # Output: mem_total, mem_used, mem_free, mem_percent, mem_status
    echo "IMPLEMENT ME"
}
```

**Useful commands to explore:**
- `top -bn1 | grep "Cpu(s)"` -- shows CPU idle percentage
- `/proc/stat` -- raw CPU counters
- `free -m` -- memory usage in megabytes (row 2 has total, used, free)

---

## Part C: Disk Usage Module (10 min)

```bash
# ============================================
# MODULE 4: DISK USAGE
# ============================================
get_disk_info() {
    # TODO: Check all mounted filesystems
    # Use: df -h
    # For each filesystem:
    #   - Get mount point, size, used, available, percentage
    #   - Flag if above DISK_WARN or DISK_CRIT thresholds
    echo "IMPLEMENT ME"
}
```

**Useful commands to explore:**
- `df -h --output=target,size,used,avail,pcent` -- formatted disk usage
- `-x tmpfs -x devtmpfs` -- exclude virtual filesystems

---

## Part D: Network Connectivity Module (10 min)

```bash
# ============================================
# MODULE 5: NETWORK CHECKS
# ============================================
check_connectivity() {
    # TODO: For each service in SERVICES:
    #   - Ping it (timeout 2s)
    #   - Record latency or failure
    echo "IMPLEMENT ME"
}
```

**Useful commands to explore:**
- `ping -c 1 -W 2 HOST` -- single ping with 2-second timeout
- The `SERVICES` associative array defined in the configuration section
- `${!SERVICES[@]}` iterates over the keys

---

## Part E: Log Analysis Module (10 min)

```bash
# ============================================
# MODULE 6: LOG ANALYSIS
# ============================================
analyze_logs() {
    # TODO: Check system logs for recent errors
    # Count ERRORs, WARNINGs in the last hour
    # List the top 5 most frequent error messages
    echo "IMPLEMENT ME"
}
```

First, generate some sample logs:

```bash
# Generate sample syslog-like entries
cat > /var/log/syslog << 'EOF'
Apr  5 10:00:01 monitor-lab CRON[1234]: (root) CMD (test -x /usr/sbin/anacron)
Apr  5 10:01:15 monitor-lab kernel: ERROR: disk I/O timeout on /dev/sda1
Apr  5 10:02:30 monitor-lab sshd[5678]: Failed password for root from 192.168.1.100
Apr  5 10:02:31 monitor-lab sshd[5678]: Failed password for root from 192.168.1.100
Apr  5 10:02:32 monitor-lab sshd[5678]: Failed password for root from 192.168.1.100
Apr  5 10:03:00 monitor-lab kernel: WARNING: low memory condition
Apr  5 10:04:00 monitor-lab systemd[1]: Started Session 42 of user root.
Apr  5 10:05:00 monitor-lab kernel: ERROR: disk I/O timeout on /dev/sda1
Apr  5 10:06:00 monitor-lab nginx[9012]: ERROR: upstream timed out
Apr  5 10:07:00 monitor-lab kernel: WARNING: temperature above threshold
Apr  5 10:08:00 monitor-lab sshd[5679]: Accepted publickey for admin from 10.0.0.5
Apr  5 10:09:00 monitor-lab kernel: ERROR: disk I/O timeout on /dev/sda1
EOF
```

**What your function should output:**
- Total log lines
- Count of errors, warnings, and failed authentication attempts
- Top 5 most frequent error messages (use `grep`, `awk`, `sort`, `uniq -c`)
- A status: OK, WARNING, or CRITICAL based on error/warning counts

---

## Part F: HTML Report Generation (20 min)

This is the main integration step. Combine all modules into a single HTML report.

```bash
# ============================================
# HTML REPORT GENERATOR
# ============================================
generate_html_report() {
    # TODO: Generate a complete HTML file with:
    # - Header with timestamp and hostname
    # - System info section
    # - CPU gauge (with color based on status)
    # - Memory gauge (with color based on status)
    # - Disk usage table
    # - Network connectivity table
    # - Log analysis summary
    # - Overall health score
    echo "IMPLEMENT ME"
}
```

**Guidelines for your HTML report:**
- Use `cat > "$REPORT_FILE" << HTMLEOF ... HTMLEOF` to write the HTML
- Include inline CSS for styling (colors, tables, progress bars)
- Use color coding: green for OK, orange for WARNING, red for CRITICAL
- Calculate a health score out of 100 (deduct points for warnings and critical statuses)
- Call all your data-collection functions and embed the results in the HTML

---

## Part G: Main Function and Execution (5 min)

Add the main entry point at the bottom of the script:

```bash
# ============================================
# MAIN
# ============================================
main() {
    log "=== Starting system health check ==="

    echo "Collecting system information..."
    echo "Checking CPU..."
    echo "Checking memory..."
    echo "Checking disk..."
    echo "Checking network..."
    echo "Analyzing logs..."
    echo "Generating HTML report..."

    generate_html_report

    echo ""
    echo "================================"
    echo "  Health check complete!"
    echo "  Report: $REPORT_FILE"
    echo "================================"

    log "=== Health check complete ==="
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### Test the Complete Script

```bash
chmod +x /root/monitoring/monitor.sh
/root/monitoring/monitor.sh
```

The HTML report will be generated in `/output/`. Since we mounted this as a volume, you can open it on your Mac:

```bash
# On your Mac (outside the container):
open /tmp/tp3_output/health_report_*.html
```

---

## Part H: Schedule with Cron (5 min)

Set up the script to run every hour inside the container:

```bash
# Start cron service
service cron start

# Edit the crontab
crontab -e
```

Add a line to run the monitoring script every hour and redirect output to a log file.

Verify the cron job:

```bash
# List cron jobs
crontab -l

# Check cron is running
service cron status

# Test by running manually
/root/monitoring/monitor.sh
```

> **Cron syntax reminder**:
> ```
> * * * * *  command
> | | | | |
> | | | | +-- Day of week (0-7, 0=Sunday)
> | | | +---- Month (1-12)
> | | +------ Day of month (1-31)
> | +-------- Hour (0-23)
> +---------- Minute (0-59)
> ```


---

## Bonus Challenges

### Bonus 1: Process Monitoring

Add a module that lists the top 5 processes by CPU and memory usage. Research how to use `ps aux` with sorting options.

### Bonus 2: Historical Comparison

Modify the script to:
1. Save key metrics to a CSV file after each run
2. Compare current values with the previous run
3. Show trend arrows in the HTML report (improving/degrading)

### Bonus 3: Alert System

Add a function that writes a warning file when critical thresholds are exceeded. Think about what threshold for the health score should trigger an alert.

---

## Cleanup

When finished:

```bash
exit  # Exit the container
docker stop tp3 2>/dev/null
# Reports are available in /tmp/tp3_output/ on your Mac
```
