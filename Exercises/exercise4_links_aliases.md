# Exercise 3: Links and Aliases

| | |
|---|---|
| **Estimated Duration** | 15 minutes |
| **Objectives** | Understand hard links vs symbolic links, create and manage them, configure aliases in .bashrc |
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
- Pull required images: `docker pull ubuntu:22.04`
- Both options work equally well for this exercise

> **Note:** Commands shown use Docker. If you are using a VM, skip the `docker run` commands and run the Linux commands directly in your VM terminal.

---

## Setup

```bash
docker run -it --rm --hostname exo-links ubuntu:22.04 bash
apt update && apt install -y tree vim
```

---

## Part 1: Hard Links (15 min)

### 1.1 Understanding Inodes

Every file on Linux has an **inode** - a unique identifier that stores metadata (permissions, owner, timestamps, disk location). A filename is just a pointer to an inode.

```bash
# Create a test file
mkdir -p /tmp/links && cd /tmp/links
echo "Hello from the original file" > original.txt

# View the inode number
ls -li original.txt
```

Output:

```
1234567 -rw-r--r-- 1 root root 29 ... original.txt
```

> The first number (`1234567`) is the inode. The `1` after the permissions is the **link count** (number of names pointing to this inode).

### 1.2 Create a Hard Link

```bash
# Create a hard link
ln original.txt hardlink.txt

# View both files with inode numbers
ls -li original.txt hardlink.txt
```

**Questions:**
- What inode numbers do you see? Are they the same or different?
- What is the link count now?

### 1.3 Hard Links Share Content

```bash
# Modify the content through the hard link
echo "Modified through hardlink" >> hardlink.txt

# The original also shows the change
cat original.txt
```

**Question:** Why does modifying one file affect the other?

### 1.4 Deleting with Hard Links

```bash
# Delete the original
rm original.txt

# The hard link still works - data is not lost!
cat hardlink.txt
ls -li hardlink.txt  # Link count is back to 1
```

> **Key takeaway**: Data is only deleted when the link count reaches 0. Hard links are additional names for the same data.

### 1.5 Hard Link Limitations

```bash
# Cannot create a hard link to a directory
mkdir testdir
ln testdir testdir_link 2>&1
# Output: hard link not allowed for directory
```

**Question:** Why are hard links to directories not allowed? (Think about the filesystem tree structure.)

---

## Part 2: Symbolic Links (Symlinks) (15 min)

### 2.1 Create a Symbolic Link

```bash
# Create a new original file
echo "I am the target file" > /tmp/links/target.txt

# Create a symbolic link
ln -s /tmp/links/target.txt /tmp/links/symlink.txt

# View both
ls -li /tmp/links/target.txt /tmp/links/symlink.txt
```

**Questions:**
- Are the inode numbers the same or different?
- What does the `l` at the beginning of the symlink's permissions mean?
- What does the `->` notation show?

### 2.2 Reading Through a Symlink

```bash
# Reading the symlink reads the target
cat /tmp/links/symlink.txt

# Modifying through the symlink modifies the target
echo "Appended through symlink" >> /tmp/links/symlink.txt
cat /tmp/links/target.txt
```

### 2.3 Breaking a Symlink

```bash
# Delete the target
rm /tmp/links/target.txt

# The symlink still exists but is broken
ls -l /tmp/links/symlink.txt   # Shows in red (broken link)
cat /tmp/links/symlink.txt 2>&1
# Output: No such file or directory

# The symlink points to nothing
file /tmp/links/symlink.txt
# Output: broken symbolic link to /tmp/links/target.txt
```

### 2.4 Restoring a Broken Symlink

```bash
# Recreate the target file
echo "I am the restored target" > /tmp/links/target.txt

# The symlink works again!
cat /tmp/links/symlink.txt
```

### 2.5 Symlinks to Directories

```bash
# Create a directory structure
mkdir -p /tmp/links/projects/webapp/src
echo "console.log('hello')" > /tmp/links/projects/webapp/src/app.js

# Create a symlink to the directory
ln -s /tmp/links/projects/webapp /tmp/links/current_project

# Navigate through the symlink
ls /tmp/links/current_project/src/
cat /tmp/links/current_project/src/app.js
```

### 2.6 Relative vs Absolute Symlinks

```bash
cd /tmp/links

# Absolute symlink (uses full path)
ln -s /tmp/links/target.txt absolute_link.txt

# Relative symlink (uses path relative to the link's location)
ln -s target.txt relative_link.txt

# Both work from the current location
cat absolute_link.txt
cat relative_link.txt

# View the difference
ls -l absolute_link.txt relative_link.txt
```

> **Best practice**: Use absolute paths for system-level symlinks. Use relative paths for symlinks within a project (they survive being moved together).

---

## Part 3: Hard Links vs Symbolic Links Comparison

### Exercise: Fill in the Table

Based on the experiments you just performed, complete this comparison table:

| Feature | Hard Link | Symbolic Link |
|---|---|---|
| Same inode as target? | Yes | No (own inode) |
| Works across filesystems? | No | Yes |
| Can link to directories? | No | Yes |
| Survives target deletion? | Yes (data persists) | No (becomes broken) |
| Shows `->` in `ls -l`? | No | Yes |
| File type indicator | `-` (regular file) | `l` (link) |

---

## Part 4: Aliases (10 min)

### 4.1 Creating Temporary Aliases

Aliases are shortcuts for commands. They last only for the current session.

```bash
# Create aliases
alias ll='ls -la'
alias cls='clear'
alias ports='ss -tulnp'
alias ..='cd ..'
alias ...='cd ../..'

# Test them
ll /tmp
..
pwd
```

### 4.2 List and Remove Aliases

```bash
# List all aliases
alias

# Remove a specific alias
unalias cls

# Verify it's gone
cls 2>&1  # Command not found
```

### 4.3 Persistent Aliases in .bashrc

To make aliases permanent, add them to `~/.bashrc`. Create a set of useful aliases for:
- **Navigation**: shortcuts for listing files and changing directories
- **Safety**: interactive mode for destructive commands (`rm`, `cp`, `mv`)
- **System info**: quick access to disk, memory, and port information
- **Shortcuts**: common operations like updating packages, clearing the screen

> **Hint**: Use `cat >> ~/.bashrc << 'EOF' ... EOF` to append a block. Don't forget to `source ~/.bashrc` afterward.

```bash
# Edit .bashrc
cat >> ~/.bashrc << 'EOF'

# === Custom Aliases ===
# Navigation
alias ll='ls -la --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd ~'

# Safety
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System info
alias ports='ss -tulnp'
alias mem='free -h'
alias disk='df -h'
alias top10='du -sh * 2>/dev/null | sort -rh | head -10'

# Shortcuts
alias update='apt update && apt upgrade -y'
alias cls='clear'
alias h='history'
alias grep='grep --color=auto'
EOF

# Reload .bashrc
source ~/.bashrc

# Test the new aliases
ll /tmp
disk
```

### 4.4 Useful Alias Patterns

Try creating these advanced aliases:

1. An alias `mkcd` that creates a directory and changes into it in one step
2. An alias `extract` that detects archive types (`.tar.gz`, `.zip`, `.bz2`) and uses the appropriate extraction command

> **Hint**: You can embed a function inside an alias: `alias name='function _f(){ ...; }; _f'`

```bash
alias mkcd='function _mkcd(){ mkdir -p "$1" && cd "$1"; }; _mkcd'

alias extract='function _extract(){
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.zip)     unzip "$1" ;;
      *)         echo "Cannot extract $1" ;;
    esac
  else
    echo "$1 is not a valid file"
  fi
}; _extract'

```

### 4.5 Bypassing an Alias

```bash
# If rm is aliased to rm -i, you can bypass it:
\rm file.txt       # Backslash ignores the alias
command rm file.txt # 'command' also bypasses aliases
/bin/rm file.txt   # Full path bypasses aliases
```

---

## Verification

Check that you have mastered the following:

- [ ] Create a hard link with `ln` and understand inodes
- [ ] Create a symbolic link with `ln -s`
- [ ] Explain the difference between hard and symbolic links
- [ ] Create and break a symlink, then restore it
- [ ] Create aliases (temporary and persistent)
- [ ] Know how to bypass an alias

**Final test**: Create a directory `/tmp/final_test`, create a file `data.txt` inside it with some content, create both a hard link and a symlink to it, then delete the original and verify which link still works.

---

## Common Pitfalls

| Pitfall | Explanation |
|---|---|
| Relative symlinks break when moved | A relative symlink is resolved from the link's location, not from where you are |
| Aliasing `rm` to `rm -i` | Gives a false sense of security; scripts and other tools won't use your alias |
| Circular symlinks | `ln -s a b && ln -s b a` creates an infinite loop |
| Hard links on directories | Not allowed (would break the filesystem tree structure) |
| Forgetting `source ~/.bashrc` | Changes to .bashrc only take effect after sourcing or opening a new shell |

> Solutions are available from your trainer.
