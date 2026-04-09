#!/bin/bash
# monitor.sh - System Health Check Script (COMPLETE SOLUTION)
# Author: Utopios Training
# Date: 2026-04-09

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================
REPORT_DIR="/output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/health_report_${TIMESTAMP}.html"
LOG_FILE="/var/log/monitoring/monitor.log"
CSV_FILE="/var/log/monitoring/metrics_history.csv"

# Thresholds
CPU_WARN=70
CPU_CRIT=90
MEM_WARN=70
MEM_CRIT=90
DISK_WARN=70
DISK_CRIT=90
HEALTH_ALERT_THRESHOLD=50

# Services to check
declare -A SERVICES
SERVICES[Google_DNS]="8.8.8.8"
SERVICES[Cloudflare_DNS]="1.1.1.1"

# ============================================
# LOGGING
# ============================================
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# ============================================
# MODULE 1: SYSTEM INFO
# ============================================
get_system_info() {
    echo "hostname=$(hostname)"
    echo "kernel=$(uname -r)"
    echo "os=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "uptime=$(uptime -p 2>/dev/null || uptime)"
    echo "date=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "users=$(who 2>/dev/null | wc -l)"
}

# ============================================
# MODULE 2: CPU USAGE
# ============================================
get_cpu_usage() {
    # Extract CPU idle percentage from top, calculate usage
    local idle
    idle=$(top -bn1 | grep "Cpu(s)" | awk '{for(i=1;i<=NF;i++) if($i ~ /id/) print $(i-1)}' | tr -d '%,')

    # Fallback: parse from /proc/stat if top output is unexpected
    if [[ -z "$idle" || "$idle" == "" ]]; then
        local cpu_line
        cpu_line=$(head -1 /proc/stat)
        local user nice system idle_val iowait irq softirq
        read -r _ user nice system idle_val iowait irq softirq <<< "$cpu_line"
        local total=$((user + nice + system + idle_val + iowait + irq + softirq))
        if [[ $total -gt 0 ]]; then
            idle=$(echo "scale=1; $idle_val * 100 / $total" | bc)
        else
            idle=100
        fi
    fi

    local cpu_percent
    cpu_percent=$(echo "scale=1; 100 - $idle" | bc)

    # Determine status
    local cpu_status="OK"
    local cpu_int=${cpu_percent%.*}
    if [[ $cpu_int -ge $CPU_CRIT ]]; then
        cpu_status="CRITICAL"
    elif [[ $cpu_int -ge $CPU_WARN ]]; then
        cpu_status="WARNING"
    fi

    echo "cpu_percent=$cpu_percent"
    echo "cpu_status=$cpu_status"
}

# ============================================
# MODULE 3: MEMORY USAGE
# ============================================
get_memory_info() {
    local mem_total mem_used mem_free mem_percent mem_status

    # Parse free -m output (line 2: Mem:)
    mem_total=$(free -m | awk '/^Mem:/ {print $2}')
    mem_used=$(free -m | awk '/^Mem:/ {print $3}')
    mem_free=$(free -m | awk '/^Mem:/ {print $4}')

    if [[ $mem_total -gt 0 ]]; then
        mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)
    else
        mem_percent=0
    fi

    mem_status="OK"
    local mem_int=${mem_percent%.*}
    if [[ $mem_int -ge $MEM_CRIT ]]; then
        mem_status="CRITICAL"
    elif [[ $mem_int -ge $MEM_WARN ]]; then
        mem_status="WARNING"
    fi

    echo "mem_total=$mem_total"
    echo "mem_used=$mem_used"
    echo "mem_free=$mem_free"
    echo "mem_percent=$mem_percent"
    echo "mem_status=$mem_status"
}

# ============================================
# MODULE 4: DISK USAGE
# ============================================
get_disk_info() {
    # Output one line per filesystem: mount|size|used|avail|percent|status
    df -h -x tmpfs -x devtmpfs --output=target,size,used,avail,pcent 2>/dev/null | tail -n +2 | while read -r mount size used avail pcent; do
        local pval=${pcent%%%}
        local status="OK"
        if [[ $pval -ge $DISK_CRIT ]]; then
            status="CRITICAL"
        elif [[ $pval -ge $DISK_WARN ]]; then
            status="WARNING"
        fi
        echo "${mount}|${size}|${used}|${avail}|${pcent}|${status}"
    done
}

# ============================================
# MODULE 5: NETWORK CHECKS
# ============================================
check_connectivity() {
    for name in "${!SERVICES[@]}"; do
        local host="${SERVICES[$name]}"
        local result latency status

        if result=$(ping -c 1 -W 2 "$host" 2>&1); then
            latency=$(echo "$result" | grep 'time=' | sed 's/.*time=\([0-9.]*\).*/\1/')
            status="OK"
        else
            latency="N/A"
            status="FAILED"
        fi
        echo "${name}|${host}|${latency}|${status}"
    done
}

# ============================================
# MODULE 6: LOG ANALYSIS
# ============================================
analyze_logs() {
    local log_source="/var/log/syslog"
    local total_lines=0
    local error_count=0
    local warning_count=0
    local auth_fail_count=0
    local log_status="OK"
    local top_errors=""

    if [[ -f "$log_source" ]]; then
        total_lines=$(wc -l < "$log_source")
        error_count=$(grep -ci "error" "$log_source" 2>/dev/null || echo 0)
        warning_count=$(grep -ci "warning" "$log_source" 2>/dev/null || echo 0)
        auth_fail_count=$(grep -ci "failed password\|authentication failure" "$log_source" 2>/dev/null || echo 0)

        # Top 5 most frequent error messages
        top_errors=$(grep -i "error\|warning\|failed" "$log_source" 2>/dev/null \
            | awk -F': ' '{print $NF}' \
            | sort | uniq -c | sort -rn | head -5)

        if [[ $error_count -ge 10 ]]; then
            log_status="CRITICAL"
        elif [[ $error_count -ge 3 || $warning_count -ge 5 ]]; then
            log_status="WARNING"
        fi
    fi

    echo "log_total=$total_lines"
    echo "log_errors=$error_count"
    echo "log_warnings=$warning_count"
    echo "log_auth_fails=$auth_fail_count"
    echo "log_status=$log_status"
    echo "log_top_errors<<ENDTOP"
    echo "$top_errors"
    echo "ENDTOP"
}

# ============================================
# BONUS 1: PROCESS MONITORING
# ============================================
get_top_processes() {
    echo "=== Top 5 by CPU ==="
    ps aux --sort=-%cpu 2>/dev/null | head -6
    echo ""
    echo "=== Top 5 by Memory ==="
    ps aux --sort=-%mem 2>/dev/null | head -6
}

# ============================================
# BONUS 2: HISTORICAL COMPARISON
# ============================================
save_metrics_csv() {
    local ts="$1" cpu="$2" mem="$3" health="$4"
    mkdir -p "$(dirname "$CSV_FILE")"
    if [[ ! -f "$CSV_FILE" ]]; then
        echo "timestamp,cpu_percent,mem_percent,health_score" > "$CSV_FILE"
    fi
    echo "$ts,$cpu,$mem,$health" >> "$CSV_FILE"
}

get_previous_metrics() {
    if [[ -f "$CSV_FILE" ]] && [[ $(wc -l < "$CSV_FILE") -ge 2 ]]; then
        tail -1 "$CSV_FILE"
    else
        echo ""
    fi
}

trend_arrow() {
    local current="$1" previous="$2"
    if [[ -z "$previous" || "$previous" == "" ]]; then
        echo "&#8212;"  # em dash (no data)
        return
    fi
    local diff
    diff=$(echo "$current - $previous" | bc 2>/dev/null || echo "0")
    local int_diff=${diff%.*}
    int_diff=${int_diff:-0}
    if [[ $int_diff -gt 2 ]]; then
        echo "&#9650; +${diff}"   # up arrow
    elif [[ $int_diff -lt -2 ]]; then
        echo "&#9660; ${diff}"    # down arrow
    else
        echo "&#9654; ${diff}"    # right arrow (stable)
    fi
}

# ============================================
# BONUS 3: ALERT SYSTEM
# ============================================
check_alerts() {
    local health_score="$1"
    local alert_file="/var/log/monitoring/ALERT_$(date +%Y%m%d_%H%M%S).txt"
    local score_int=${health_score%.*}

    if [[ $score_int -le $HEALTH_ALERT_THRESHOLD ]]; then
        mkdir -p "$(dirname "$alert_file")"
        cat > "$alert_file" << ALERTEOF
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SYSTEM HEALTH ALERT
  Date: $(date '+%Y-%m-%d %H:%M:%S')
  Host: $(hostname)
  Health Score: ${health_score}/100
  Threshold: ${HEALTH_ALERT_THRESHOLD}

  IMMEDIATE ATTENTION REQUIRED
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ALERTEOF
        log "ALERT: Health score $health_score is below threshold $HEALTH_ALERT_THRESHOLD. Alert file: $alert_file"
        echo "$alert_file"
    fi
}

# ============================================
# STATUS COLOR HELPER
# ============================================
status_color() {
    case "$1" in
        OK)       echo "#27ae60" ;;
        WARNING)  echo "#f39c12" ;;
        CRITICAL) echo "#e74c3c" ;;
        FAILED)   echo "#e74c3c" ;;
        *)        echo "#95a5a6" ;;
    esac
}

# ============================================
# HTML REPORT GENERATOR
# ============================================
generate_html_report() {
    log "Generating HTML report..."

    # --- Collect all data ---
    local sys_info cpu_info mem_info disk_info net_info log_info proc_info

    sys_info=$(get_system_info)
    cpu_info=$(get_cpu_usage)
    mem_info=$(get_memory_info)
    disk_info=$(get_disk_info)
    net_info=$(check_connectivity)
    log_info=$(analyze_logs)
    proc_info=$(get_top_processes)

    # Parse values
    local sys_hostname sys_kernel sys_os sys_uptime sys_date sys_users
    sys_hostname=$(echo "$sys_info" | grep '^hostname=' | cut -d= -f2-)
    sys_kernel=$(echo "$sys_info" | grep '^kernel=' | cut -d= -f2-)
    sys_os=$(echo "$sys_info" | grep '^os=' | cut -d= -f2-)
    sys_uptime=$(echo "$sys_info" | grep '^uptime=' | cut -d= -f2-)
    sys_date=$(echo "$sys_info" | grep '^date=' | cut -d= -f2-)
    sys_users=$(echo "$sys_info" | grep '^users=' | cut -d= -f2-)

    local cpu_percent cpu_status
    cpu_percent=$(echo "$cpu_info" | grep '^cpu_percent=' | cut -d= -f2)
    cpu_status=$(echo "$cpu_info" | grep '^cpu_status=' | cut -d= -f2)

    local mem_total mem_used mem_free mem_percent mem_status
    mem_total=$(echo "$mem_info" | grep '^mem_total=' | cut -d= -f2)
    mem_used=$(echo "$mem_info" | grep '^mem_used=' | cut -d= -f2)
    mem_free=$(echo "$mem_info" | grep '^mem_free=' | cut -d= -f2)
    mem_percent=$(echo "$mem_info" | grep '^mem_percent=' | cut -d= -f2)
    mem_status=$(echo "$mem_info" | grep '^mem_status=' | cut -d= -f2)

    local log_total log_errors log_warnings log_auth_fails log_status log_top_errors
    log_total=$(echo "$log_info" | grep '^log_total=' | cut -d= -f2)
    log_errors=$(echo "$log_info" | grep '^log_errors=' | cut -d= -f2)
    log_warnings=$(echo "$log_info" | grep '^log_warnings=' | cut -d= -f2)
    log_auth_fails=$(echo "$log_info" | grep '^log_auth_fails=' | cut -d= -f2)
    log_status=$(echo "$log_info" | grep '^log_status=' | cut -d= -f2)
    log_top_errors=$(echo "$log_info" | sed -n '/^log_top_errors<<ENDTOP$/,/^ENDTOP$/p' | grep -v 'ENDTOP' | grep -v 'log_top_errors')

    # --- Calculate Health Score ---
    local health_score=100

    case "$cpu_status" in
        WARNING)  health_score=$((health_score - 10)) ;;
        CRITICAL) health_score=$((health_score - 25)) ;;
    esac

    case "$mem_status" in
        WARNING)  health_score=$((health_score - 10)) ;;
        CRITICAL) health_score=$((health_score - 25)) ;;
    esac

    case "$log_status" in
        WARNING)  health_score=$((health_score - 10)) ;;
        CRITICAL) health_score=$((health_score - 20)) ;;
    esac

    # Deduct for disk issues
    while IFS='|' read -r mount size used avail pcent dstatus; do
        case "$dstatus" in
            WARNING)  health_score=$((health_score - 5)) ;;
            CRITICAL) health_score=$((health_score - 15)) ;;
        esac
    done <<< "$disk_info"

    # Deduct for network failures
    while IFS='|' read -r name host latency nstatus; do
        if [[ "$nstatus" == "FAILED" ]]; then
            health_score=$((health_score - 10))
        fi
    done <<< "$net_info"

    [[ $health_score -lt 0 ]] && health_score=0

    local health_color
    if [[ $health_score -ge 80 ]]; then
        health_color="#27ae60"
    elif [[ $health_score -ge 50 ]]; then
        health_color="#f39c12"
    else
        health_color="#e74c3c"
    fi

    # --- Bonus 2: Historical comparison ---
    local prev_metrics prev_cpu prev_mem prev_health
    local cpu_trend mem_trend health_trend
    prev_metrics=$(get_previous_metrics)
    if [[ -n "$prev_metrics" ]]; then
        prev_cpu=$(echo "$prev_metrics" | cut -d, -f2)
        prev_mem=$(echo "$prev_metrics" | cut -d, -f3)
        prev_health=$(echo "$prev_metrics" | cut -d, -f4)
        cpu_trend=$(trend_arrow "$cpu_percent" "$prev_cpu")
        mem_trend=$(trend_arrow "$mem_percent" "$prev_mem")
        health_trend=$(trend_arrow "$health_score" "$prev_health")
    else
        cpu_trend="&#8212;"
        mem_trend="&#8212;"
        health_trend="&#8212;"
    fi

    # Save current metrics for future comparison
    save_metrics_csv "$TIMESTAMP" "$cpu_percent" "$mem_percent" "$health_score"

    # --- Bonus 3: Alert check ---
    local alert_result
    alert_result=$(check_alerts "$health_score")

    # --- Generate HTML ---
    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Health Report - ${sys_hostname}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #ecf0f1;
            color: #2c3e50;
            padding: 20px;
        }
        .container { max-width: 1000px; margin: 0 auto; }
        .header {
            background: linear-gradient(135deg, #2c3e50, #3498db);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        .header h1 { font-size: 28px; margin-bottom: 5px; }
        .header .subtitle { opacity: 0.8; font-size: 14px; }
        .health-score {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 20px;
            text-align: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .health-score .score {
            font-size: 72px;
            font-weight: bold;
            color: ${health_color};
        }
        .health-score .label { font-size: 18px; color: #7f8c8d; }
        .health-score .trend { font-size: 16px; color: #95a5a6; margin-top: 5px; }
        .section {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .section h2 {
            font-size: 20px;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 2px solid #ecf0f1;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
        }
        .info-item { padding: 8px 0; }
        .info-item .label { color: #7f8c8d; font-size: 13px; }
        .info-item .value { font-size: 16px; font-weight: 500; }
        .gauge-container {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }
        .gauge {
            flex: 1;
            min-width: 200px;
            text-align: center;
            padding: 15px;
        }
        .gauge .title { font-size: 14px; color: #7f8c8d; margin-bottom: 10px; }
        .gauge .value { font-size: 36px; font-weight: bold; }
        .gauge .trend { font-size: 13px; color: #95a5a6; margin-top: 5px; }
        .progress-bar {
            height: 12px;
            background: #ecf0f1;
            border-radius: 6px;
            margin-top: 10px;
            overflow: hidden;
        }
        .progress-bar .fill {
            height: 100%;
            border-radius: 6px;
            transition: width 0.3s;
        }
        .status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 12px;
            color: white;
            font-size: 12px;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            padding: 10px 12px;
            text-align: left;
            border-bottom: 1px solid #ecf0f1;
        }
        th { background: #f8f9fa; font-weight: 600; font-size: 13px; color: #7f8c8d; }
        td { font-size: 14px; }
        pre {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 13px;
            line-height: 1.5;
        }
        .alert-banner {
            background: #e74c3c;
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-weight: bold;
            text-align: center;
            font-size: 18px;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #95a5a6;
            font-size: 12px;
        }
    </style>
</head>
<body>
<div class="container">

    <div class="header">
        <h1>System Health Report</h1>
        <div class="subtitle">${sys_hostname} &mdash; ${sys_date}</div>
    </div>
HTMLEOF

    # Alert banner if needed
    if [[ -n "$alert_result" ]]; then
        cat >> "$REPORT_FILE" << HTMLEOF
    <div class="alert-banner">
        ALERT: Health score is critically low (${health_score}/100). Immediate attention required!
    </div>
HTMLEOF
    fi

    cat >> "$REPORT_FILE" << HTMLEOF

    <!-- Health Score -->
    <div class="health-score">
        <div class="label">Overall Health Score</div>
        <div class="score">${health_score}/100</div>
        <div class="trend">Trend: ${health_trend}</div>
    </div>

    <!-- System Info -->
    <div class="section">
        <h2>System Information</h2>
        <div class="info-grid">
            <div class="info-item">
                <div class="label">Hostname</div>
                <div class="value">${sys_hostname}</div>
            </div>
            <div class="info-item">
                <div class="label">Operating System</div>
                <div class="value">${sys_os}</div>
            </div>
            <div class="info-item">
                <div class="label">Kernel</div>
                <div class="value">${sys_kernel}</div>
            </div>
            <div class="info-item">
                <div class="label">Uptime</div>
                <div class="value">${sys_uptime}</div>
            </div>
            <div class="info-item">
                <div class="label">Logged-in Users</div>
                <div class="value">${sys_users}</div>
            </div>
            <div class="info-item">
                <div class="label">Report Generated</div>
                <div class="value">${sys_date}</div>
            </div>
        </div>
    </div>

    <!-- CPU & Memory Gauges -->
    <div class="section">
        <h2>CPU &amp; Memory</h2>
        <div class="gauge-container">
            <div class="gauge">
                <div class="title">CPU Usage</div>
                <div class="value" style="color: $(status_color "$cpu_status")">${cpu_percent}%</div>
                <span class="status-badge" style="background: $(status_color "$cpu_status")">${cpu_status}</span>
                <div class="progress-bar">
                    <div class="fill" style="width: ${cpu_percent}%; background: $(status_color "$cpu_status")"></div>
                </div>
                <div class="trend">Trend: ${cpu_trend}</div>
            </div>
            <div class="gauge">
                <div class="title">Memory Usage</div>
                <div class="value" style="color: $(status_color "$mem_status")">${mem_percent}%</div>
                <span class="status-badge" style="background: $(status_color "$mem_status")">${mem_status}</span>
                <div class="progress-bar">
                    <div class="fill" style="width: ${mem_percent}%; background: $(status_color "$mem_status")"></div>
                </div>
                <div class="trend">${mem_used} MB / ${mem_total} MB (Free: ${mem_free} MB) | Trend: ${mem_trend}</div>
            </div>
        </div>
    </div>

    <!-- Disk Usage -->
    <div class="section">
        <h2>Disk Usage</h2>
        <table>
            <tr><th>Mount Point</th><th>Size</th><th>Used</th><th>Available</th><th>Usage</th><th>Status</th></tr>
HTMLEOF

    # Write disk rows
    while IFS='|' read -r mount size used avail pcent dstatus; do
        [[ -z "$mount" ]] && continue
        cat >> "$REPORT_FILE" << HTMLEOF
            <tr>
                <td>${mount}</td>
                <td>${size}</td>
                <td>${used}</td>
                <td>${avail}</td>
                <td>${pcent}</td>
                <td><span class="status-badge" style="background: $(status_color "$dstatus")">${dstatus}</span></td>
            </tr>
HTMLEOF
    done <<< "$disk_info"

    cat >> "$REPORT_FILE" << HTMLEOF
        </table>
    </div>

    <!-- Network Connectivity -->
    <div class="section">
        <h2>Network Connectivity</h2>
        <table>
            <tr><th>Service</th><th>Host</th><th>Latency</th><th>Status</th></tr>
HTMLEOF

    while IFS='|' read -r name host latency nstatus; do
        [[ -z "$name" ]] && continue
        local latency_display
        if [[ "$latency" != "N/A" ]]; then
            latency_display="${latency} ms"
        else
            latency_display="N/A"
        fi
        cat >> "$REPORT_FILE" << HTMLEOF
            <tr>
                <td>${name}</td>
                <td>${host}</td>
                <td>${latency_display}</td>
                <td><span class="status-badge" style="background: $(status_color "$nstatus")">${nstatus}</span></td>
            </tr>
HTMLEOF
    done <<< "$net_info"

    cat >> "$REPORT_FILE" << HTMLEOF
        </table>
    </div>

    <!-- Log Analysis -->
    <div class="section">
        <h2>Log Analysis</h2>
        <div class="info-grid">
            <div class="info-item">
                <div class="label">Total Log Lines</div>
                <div class="value">${log_total}</div>
            </div>
            <div class="info-item">
                <div class="label">Status</div>
                <div class="value"><span class="status-badge" style="background: $(status_color "$log_status")">${log_status}</span></div>
            </div>
            <div class="info-item">
                <div class="label">Errors</div>
                <div class="value" style="color: #e74c3c">${log_errors}</div>
            </div>
            <div class="info-item">
                <div class="label">Warnings</div>
                <div class="value" style="color: #f39c12">${log_warnings}</div>
            </div>
            <div class="info-item">
                <div class="label">Auth Failures</div>
                <div class="value" style="color: #e74c3c">${log_auth_fails}</div>
            </div>
        </div>
        <h3 style="margin-top: 15px; margin-bottom: 10px; font-size: 16px;">Top Error Messages</h3>
        <pre>$(echo "$log_top_errors" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre>
    </div>

    <!-- Bonus 1: Top Processes -->
    <div class="section">
        <h2>Top Processes</h2>
        <pre>$(echo "$proc_info" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre>
    </div>

    <div class="footer">
        Generated by System Health Monitor &mdash; $(date '+%Y-%m-%d %H:%M:%S')
    </div>

</div>
</body>
</html>
HTMLEOF

    log "Report generated: $REPORT_FILE"
}

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
