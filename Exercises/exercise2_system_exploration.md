# Exercise 5: System Architecture Exploration

| | |
|---|---|
| **Estimated Duration** | 45 minutes |
| **Objectives** | Explore virtual filesystems /proc and /sys, analyze kernel modules, discover systemd services and targets, compare shells (bash vs sh) |
| **Prerequisites** | See below |
| **Difficulty** | Intermediate |

### Prerequisites

Choose ONE of the following environments:

**Option A -- Virtual Machine (recommended for full system access)**
- A Linux VM (Ubuntu 22.04+ or Debian 12 recommended)
- Install via VirtualBox, UTM (macOS), VMware, or Hyper-V
- Minimum: 2 GB RAM, 20 GB disk
- Snapshot your VM before each lab

**Option B -- Docker Container**
- Docker Desktop installed and running
- Pull required images: `docker pull ubuntu:24.04`
- Both options work equally well for this exercise

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` commands and run the Linux commands directly in your VM terminal. Parts 3 (Systemd) requires a VM for full functionality -- in Docker, the commands are shown but may not produce output.

---

## Environment Setup

Launch an Ubuntu container that will serve as the working environment:

```bash
docker run -it --rm --hostname sysexplore --name exo5 ubuntu:24.04 bash
```

Install required tools:

```bash
apt update && apt install -y kmod procps pciutils zsh util-linux
```

---

## Part 1: Exploring /proc -- The Kernel's Window (10 min)

### 1.1 System Identity

Run the following commands and note the output for each:

```bash
# Kernel version
cat /proc/version

# Kernel boot parameters
cat /proc/cmdline

# System uptime (in seconds)
cat /proc/uptime

# Load average (1, 5, 15 minutes)
cat /proc/loadavg

# Hostname
cat /proc/sys/kernel/hostname
```

**Questions:**
- What is the kernel version running on your system?
- What does the first number in `/proc/uptime` represent? What about the second?
- What do the three numbers in `/proc/loadavg` mean?

### 1.2 CPU and Memory

```bash
# How many CPU cores are available?
grep -c "^processor" /proc/cpuinfo

# What is the CPU model?
grep "model name" /proc/cpuinfo | head -1

# Total available memory (in kB)
grep "MemTotal" /proc/meminfo

# Available memory
grep "MemAvailable" /proc/meminfo

# Swap information
grep "Swap" /proc/meminfo
```

**Questions:**
- How many CPU cores does your system have?
- How much total RAM is available (convert to GB)?
- Is swap enabled? How much?

### 1.3 Exploring /proc for Processes

```bash
# List process directories in /proc (each number is a PID)
ls /proc/ | grep -E "^[0-9]+$" | head -10

# Look at PID 1 (the init process)
cat /proc/1/cmdline | tr '\0' ' ' && echo

# Current process status
cat /proc/self/status | head -15
```

**Questions:**
- What is running as PID 1 in your container? What would it be on a VM?
- What does `/proc/self` refer to?

---

## Part 2: Kernel Modules (10 min)

### 2.1 List and Count Modules

```bash
# List all loaded modules
lsmod

# Count them
lsmod | tail -n +2 | wc -l

# Sort by size (largest first)
lsmod | tail -n +2 | sort -k2 -n -r | head -10
```

### 2.2 Investigate 3 Modules

Pick **3 modules** from the `lsmod` output and research what they do:

```bash
# Example: investigate the "overlay" module
modinfo overlay

# Show only the description
modinfo -d overlay 2>/dev/null

# Show the filename
modinfo -n overlay 2>/dev/null
```

For each of your 3 chosen modules, fill in this table:

| Module Name | Description | Size | Used by |
|---|---|---|---|
| (module 1) | ... | ... | ... |
| (module 2) | ... | ... | ... |
| (module 3) | ... | ... | ... |

### 2.3 Module Dependencies

```bash
# Show what a module depends on
modinfo bridge | grep "depends"

# Show what modules use the bridge module
lsmod | grep bridge
```

**Question:** Why is it important to understand module dependencies before removing a module?

---

## Part 3: Systemd Services and Targets (10 min)

> **Note:** This part requires a VM for full functionality. In Docker, the commands are shown with expected output. If you are using Docker, read through the commands and expected outputs, then answer the questions based on the expected output shown.

### 3.1 List Active Services (VM only)

```bash
# List all running services
systemctl list-units --type=service --state=running
```

**Task:** Count the number of running services and identify at least 5 that you recognize.

### 3.2 Default Target (VM only)

```bash
# What is the default target (boot mode)?
systemctl get-default

# List all targets
systemctl list-units --type=target --state=active
```

**Questions:**
- What is your system's default target?
- What is the difference between `multi-user.target` and `graphical.target`?

### 3.3 Boot Time Analysis (VM only)

```bash
# Overall boot time
systemd-analyze

# Top 10 slowest services
systemd-analyze blame | head -10
```

**Task:** Identify the 3 slowest services at boot. Research what each one does.

### 3.4 Inspect a Service (VM only)

```bash
# Choose a service and inspect it
systemctl status ssh.service

# Read its unit file
systemctl cat ssh.service
```

**Questions:**
- In the unit file, what does the `After=` directive mean?
- What does `WantedBy=multi-user.target` in the `[Install]` section mean?

---

## Part 4: Comparing Shells -- bash vs sh (15 min)

### 4.1 Identify Your Shells

```bash
# Current shell
echo $SHELL

# All available shells
cat /etc/shells

# Verify what /bin/sh actually is
ls -la /bin/sh
```

**Question:** On Ubuntu, what is `/bin/sh` linked to?

### 4.2 Test: Command Substitution

Try both syntaxes in each shell:

```bash
# In bash
bash -c 'echo "Today is $(date +%A)"'
bash -c 'echo "Today is `date +%A`"'

# In sh
sh -c 'echo "Today is $(date +%A)"'
sh -c 'echo "Today is `date +%A`"'
```

**Question:** Do both syntaxes work in both shells?

### 4.3 Test: Arrays

```bash
# In bash -- arrays work
bash -c '
fruits=("apple" "banana" "cherry")
echo "Second fruit: ${fruits[1]}"
echo "All fruits: ${fruits[@]}"
echo "Count: ${#fruits[@]}"
'

# In sh -- arrays do NOT work
sh -c '
fruits=("apple" "banana" "cherry")
echo "This will fail"
'
```

**Question:** What error do you get in `sh`? Why?

### 4.4 Test: Brace Expansion

```bash
# In bash
bash -c 'echo {1..5}'
bash -c 'echo {a..e}'
bash -c 'echo file_{01..05}.txt'

# In sh
sh -c 'echo {1..5}'
sh -c 'echo {a..e}'
sh -c 'echo file_{01..05}.txt'
```

**Question:** What is the output in each shell?

### 4.5 Test: Advanced Conditionals

```bash
# In bash -- [[ ]] supports regex and pattern matching
bash -c '
name="Linux2024"
if [[ $name =~ ^Linux[0-9]+$ ]]; then
    echo "Matches the pattern"
fi
'

# In sh -- [[ ]] does NOT work
sh -c '
name="Linux2024"
if [[ $name =~ ^Linux[0-9]+$ ]]; then
    echo "This will fail"
fi
'
```

**Question:** What must you use instead of `[[ ]]` in sh?

### 4.6 Summary Table

Fill in this table based on your tests:

| Feature | bash | sh (dash) | Works in both? |
|---|---|---|---|
| Command substitution `$(...)` | ? | ? | ? |
| Arrays | ? | ? | ? |
| Brace expansion `{1..5}` | ? | ? | ? |
| `[[ ]]` conditionals | ? | ? | ? |
| Functions `function f() {}` | ? | ? | ? |

---

## Part 5: System Information Roundup (5 min)

Collect the following information using only the commands you have learned. Write down each answer:

1. **Kernel version**: _____________
2. **Architecture** (x86_64, arm64...): _____________
3. **Hostname**: _____________
4. **Uptime** (human-readable): _____________
5. **Load average** (1 min): _____________
6. **Total RAM** (in GB): _____________
7. **Number of CPU cores**: _____________
8. **Number of loaded kernel modules**: _____________
9. **Default shell**: _____________
10. **PID 1 process name**: _____________



---

## Verification

Before exiting the container, verify that you can:

- [ ] Read system information from `/proc` (version, cpuinfo, meminfo, uptime, loadavg)
- [ ] Explore `/sys` to find device information (network interfaces, block devices)
- [ ] List kernel modules with `lsmod` and inspect them with `modinfo`
- [ ] Explain the difference between `/proc` and `/sys`
- [ ] Identify systemd targets and understand their role in the boot process
- [ ] Demonstrate at least 3 features that work in `bash` but not in `sh`
- [ ] Find kernel version, architecture, hostname, uptime, and load average from memory

**Final test**: Without looking at the instructions, write a single command line that outputs:
`Kernel: <version> | Arch: <architecture> | Cores: <count> | RAM: <total_in_kB>`

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| `systemctl` in Docker | Standard containers do not run systemd as PID 1. Use a VM for systemd exploration. |
| `/proc/cpuinfo` shows the host | In Docker, `/proc` reflects the **host** kernel, not the container. CPU/memory info is the host's. |
| Confusing `/proc` and `/sys` | `/proc` = processes and kernel state. `/sys` = hardware and device tree. |
| Writing `#!/bin/sh` but using bash features | If your script uses arrays, `[[ ]]`, or brace expansion, use `#!/bin/bash` as the shebang. |
| `lsmod` shows nothing in minimal containers | Some Docker images have no loaded modules visible. This depends on the host kernel configuration. |
| Forgetting `tr '\0' ' '` for `/proc/*/cmdline` | Arguments in cmdline files are separated by null bytes (`\0`), not spaces. |

> Solutions are available from your trainer.
