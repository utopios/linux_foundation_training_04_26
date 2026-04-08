# Exercise 2: Exploring the Linux File System

| | |
|---|---|
| **Estimated Duration** | 30-45 minutes |
| **Objectives** | Understand the FHS hierarchy, identify file types, master find and disk usage commands |
| **Prerequisites** | See below |
| **Difficulty** | Easy to Intermediate |

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
- Both options work equally well for this exercise

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` commands and run the Linux commands directly in your VM terminal.

---

## Setup

```bash
docker run -it --rm --hostname exo-fs ubuntu:22.04 bash
apt update && apt install -y tree file findutils man-db
```

---

## Part 1: The FHS (Filesystem Hierarchy Standard) (10 min)

The FHS defines how directories are organized on Linux. Explore each directory and note its role.

### 1.1 Explore the Main Directories

For each directory below, use `ls` to list its contents and guess its purpose:

```bash
ls /bin
ls /sbin
ls /etc
ls /var
ls /tmp
ls /home
ls /usr
ls /usr/bin
ls /usr/lib
ls /opt
ls /dev
ls /proc
ls /sys
```

### 1.2 Questions

Fill in the following table based on your exploration:

| Directory | Your Answer |
|---|---|
| `/bin` | ? |
| `/sbin` | ? |
| `/etc` | ? |
| `/var` | ? |
| `/var/log` | ? |
| `/tmp` | ? |
| `/home` | ? |
| `/usr` | ? |
| `/opt` | ? |
| `/dev` | ? |
| `/proc` | ? |

### 1.3 Explore /proc (Virtual Filesystem)

```bash
# CPU information
cat /proc/cpuinfo | head -20

# Memory information
cat /proc/meminfo | head -10

# Kernel version
cat /proc/version

# Uptime in seconds
cat /proc/uptime

# Kernel command line
cat /proc/cmdline
```

> **Key point**: `/proc` does not contain real files. These are interfaces to kernel data, generated on the fly.

---

## Part 2: Identifying File Types (10 min)

### 2.1 The `file` Command

Run `file` on different elements and observe the results:

```bash
# A script
echo '#!/bin/bash' > /tmp/test.sh
file /tmp/test.sh

# A binary
file /bin/bash

# A symbolic link
file /usr/bin/awk

# A directory
file /etc

# A text file
file /etc/hostname

# A device file
file /dev/null
file /dev/zero
```

### 2.2 Linux File Types

Use `ls -la` to identify types by the first character:

```bash
ls -la /dev/null    # c = character device
ls -la /dev/sda 2>/dev/null || echo "No physical disk in the container"
ls -la /tmp         # d = directory
ls -la /bin/bash    # - = regular file
ls -la /usr/bin/awk # l = symbolic link
```

**Exercise**: Complete this table:

| Character | Type | Example |
|---|---|---|
| `-` | ? | ? |
| `d` | ? | ? |
| `l` | ? | ? |
| `c` | ? | ? |
| `b` | ? | ? |
| `p` | ? | ? |
| `s` | ? | ? |

---

## Part 3: Searching for Files with find (15 min)

### 3.1 Prepare Test Data

```bash
# Create a test file tree
mkdir -p /tmp/search/{project1,project2,archives}
touch /tmp/search/project1/{main.py,utils.py,config.yml,README.md}
touch /tmp/search/project2/{app.js,package.json,style.css}
touch /tmp/search/archives/{backup_2024.tar.gz,old_config.yml}
echo "ERROR: connection refused" > /tmp/search/project1/error.log
echo "INFO: startup OK" > /tmp/search/project2/app.log
chmod 755 /tmp/search/project1/main.py
chmod 644 /tmp/search/project2/app.js
```

### 3.2 Search by Name

```bash
# Find all .py files
find /tmp/search -name "*.py"

# Find all .yml files (case insensitive)
find /tmp/search -iname "*.yml"

# Find README files
find /tmp/search -name "README*"
```

### 3.3 Search by Type

```bash
# Find only directories
find /tmp/search -type d

# Find only regular files
find /tmp/search -type f

# Find empty files
find /tmp/search -type f -empty
```

### 3.4 Search by Size and Date

```bash
# Files larger than 0 bytes (non-empty)
find /tmp/search -type f -size +0c

# Files modified in the last 10 minutes
find /tmp/search -type f -mmin -10

# Files modified more than 1 day ago
find /tmp/search -type f -mtime +1
```

### 3.5 Search by Permissions

```bash
# Executable files
find /tmp/search -type f -perm -755

# World-readable files
find /tmp/search -type f -perm -644
```

### 3.6 Combinations and Actions

```bash
# Find .log files and display their content
find /tmp/search -name "*.log" -exec cat {} \;

# Find .py files and count their lines
find /tmp/search -name "*.py" -exec wc -l {} \;

# Find .yml AND .json files
find /tmp/search -name "*.yml" -o -name "*.json"

# Find files that are NOT .log files
find /tmp/search -type f ! -name "*.log"
```

### 3.7 Practical find Exercise

Without looking at the examples above, write the `find` commands to:

1. Find all `.css` files in `/tmp/search`
2. Find all directories named exactly `project1`
3. Find all files larger than 5 bytes
4. Find all `.log` files and delete them (with confirmation)
5. Find all files and display their type with `file`

---

## Part 4: Disk Usage (5 min)

### 4.1 Global View with df

```bash
# Disk space in human-readable format
df -h

# Only the main filesystem
df -h /

# Filesystem type
df -Th
```

### 4.2 Per-Directory Usage with du

```bash
# Directory size
du -sh /tmp/search

# Detail per subdirectory
du -h /tmp/search

# Top 5 largest directories in /usr
du -h /usr --max-depth=1 2>/dev/null | sort -rh | head -5
```

### 4.3 Quick Exercise

Find the 3 largest files in `/usr/bin`. Which commands and options will you use?

---

## Verification

Check that you have mastered the following:

- [ ] Know the purpose of the main FHS directories (`/etc`, `/var`, `/tmp`, `/home`, `/usr`, `/proc`)
- [ ] Identify file types with `file` and `ls -l`
- [ ] Use `find` with criteria: `-name`, `-type`, `-size`, `-mtime`, `-exec`
- [ ] Analyze disk space with `df` and `du`

**Final test**: Write a single `find` command that finds all `.py` or `.js` files in `/tmp/search` that are larger than 0 bytes, and displays their full path along with their type.

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| `find -name *.py` without quotes | The shell expands `*` before passing it to find. Always use `"*.py"`. |
| Forgetting `-type f` | Without the type filter, `find` also returns directories. |
| `du` without `--max-depth` | Can produce very long output on large systems. |
| `/proc` is not a real FS | Do not try to copy or back up `/proc`. |
| `-exec {} \;` vs `-exec {} +` | `\;` runs the command once per file, `+` groups files into a single call (faster). |

> Solutions are available from your trainer.
