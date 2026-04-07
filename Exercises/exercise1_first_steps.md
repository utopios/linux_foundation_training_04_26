# Exercise 1: First Steps in the Linux Terminal

| | |
|---|---|
| **Estimated Duration** | 30-45 minutes |
| **Objectives** | Master terminal navigation, create files and directories, use system info commands, read man pages |
| **Prerequisites** | See below |
| **Difficulty** | Easy |

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

## Environment Setup

Launch an Ubuntu container that will serve as the working environment for the entire exercise:

```bash
docker run -it --rm --hostname myserver --name exo1 ubuntu:22.04 bash
```

> **Tip**: The `--hostname myserver` option customizes the machine name displayed in the prompt.

---

## Part 1: Terminal Navigation (10 min)

### 1.1 Orient Yourself

Run the following commands and note the output:

```bash
# Where am I?
pwd

# Who am I?
whoami

# What is the machine name?
hostname
```

**Questions**:
- What directory are you in by default?
- Which user are you logged in as?

### 1.2 Explore the File Hierarchy

```bash
# List the contents of the current directory
ls

# List with details
ls -la

# Go to root
cd /

# List the main directories
ls -la

# Explore some important directories
ls /etc
ls /var
ls /tmp
ls /home
ls /usr/bin
```

### 1.3 Advanced Navigation

Follow this path:

```bash
# Go to /etc
cd /etc

# Check your position
pwd

# Go to /var/log
cd /var/log

# Return to the previous directory
cd -

# Where are you now?
pwd

# Go to your home directory
cd ~
# or simply
cd

# Check
pwd

# Go up one level
cd ..
pwd

# Go up two levels
cd ../..
pwd
```

**Questions**:
- What does `cd -` do?
- What is the difference between `cd ~` and `cd` with no argument?
- What does `..` mean in a path?

---

## Part 2: Creating Files and Directories (15 min)

### 2.1 Build a Directory Tree

Create the following structure in your home directory:

```
~/project/
├── src/
│   ├── main.sh
│   └── utils.sh
├── docs/
│   └── README.md
├── logs/
└── config/
    └── app.conf
```

**Task**: Using `mkdir`, `mkdir -p`, and `touch`, create this entire structure. Think about the order of operations.

### 2.2 Verify the Structure

```bash
# Install tree for visualization (apt is needed in the container)
apt update && apt install -y tree

# Visualize the tree
tree ~/project
```

Does your output match the expected structure above?

### 2.3 Write Content into Files

Using `echo`, `>>`, and `cat` with here-documents:

1. Write a shebang (`#!/bin/bash`) and an echo command into `~/project/src/main.sh`
2. Write a multi-line README into `~/project/docs/README.md` that describes the project structure

> **Hint**: `>` overwrites, `>>` appends. `cat > file << 'EOF'` lets you write multiple lines.

Verify your content with `cat`.

### 2.4 Copy, Move, Rename

Perform the following operations and verify after each step with `tree ~/project`:

1. Copy `main.sh` to `main_backup.sh` (in the same directory)
2. Move `main_backup.sh` into the `logs/` directory
3. Rename it to `backup_main.sh`
4. Copy the entire `src/` directory to `src_backup/`

### 2.5 Delete

1. Delete the file `backup_main.sh`
2. Delete the empty `logs/` directory (which command handles empty directories?)
3. Delete the `src_backup/` directory and its contents

> **Warning**: `rm -r` is irreversible. There is no trash can on the command line. In production, prefer `mv` to a temporary directory rather than `rm`.

---

## Part 3: System Information Commands (10 min)

### 3.1 System Info

Run each command and note what it displays:

```bash
# Kernel information
uname -a

# Kernel version only
uname -r

# Architecture
uname -m

# Machine name
hostname

# Uptime
uptime

# Date and time
date

# Calendar
cal
```

### 3.2 Resource Information

```bash
# Disk space
df -h

# Memory usage (install procps first)
apt install -y procps
free -h

# Running processes
ps aux

# Environment variables
env

# A specific variable
echo $HOME
echo $PATH
echo $SHELL
```

### 3.3 File Information

```bash
# Directory size
du -sh ~/project

# Detailed size
du -h ~/project

# File type
file ~/project/src/main.sh
file /bin/bash
file /etc/os-release

# Line, word, character count
wc ~/project/docs/README.md
wc -l ~/project/docs/README.md
```

---

## Part 4: Reading the Manual (5 min)

### 4.1 The man Command

```bash
# Install the manual (not present by default in containers)
apt install -y man-db manpages

# Read the manual for ls
man ls
```

> **Navigating man**: `q` to quit, `/word` to search, `n` for next occurrence, `Space` for next page.

### 4.2 Alternatives to man

```bash
# Short built-in help
ls --help

# Short description of a command
whatis ls

# Command type (builtin, external, alias)
type cd
type ls
type echo
```

### 4.3 Practical Exercise with the Manual

Use `man` or `--help` to answer the following questions:

1. Which option of `ls` sorts by modification time?
2. Which option of `cp` copies recursively?
3. Which option of `mkdir` creates parent directories?
4. Which option of `rm` prompts for confirmation before deletion?

---

## Verification

Before exiting the container, verify that you can:

- [ ] Navigate the file hierarchy with `cd`, `pwd`, `ls`
- [ ] Create files (`touch`, `echo >`, `cat >`) and directories (`mkdir`)
- [ ] Copy (`cp`), move (`mv`), delete (`rm`) files and directories
- [ ] Obtain system information (`uname`, `hostname`, `uptime`, `df`, `free`)
- [ ] Read the manual (`man`, `--help`)

**Final test**: Without looking at the instructions, create a directory `/tmp/test/a/b/c` in a single command, then create a file `hello.txt` containing "Hello Linux" inside it, and display its contents.

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| `rm -rf /` | **NEVER** run this command! It deletes the entire system. |
| Spaces in names | Use quotes: `mkdir "my folder"` or escape: `mkdir my\ folder` |
| Forgetting `-p` with `mkdir` | Without `-p`, `mkdir a/b/c` fails if `a/b` does not exist |
| Confusing `>` and `>>` | `>` overwrites the file, `>>` appends to the end |
| Relative vs absolute paths | `/etc` is absolute, `etc` is relative to the current directory |

> Solutions are available from your trainer.
