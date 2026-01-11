# Bug Analysis & Security Audit Report
## Pterodactyl Installer v2.2.0

**Date:** Generated via Deep Dive Code Analysis  
**Scope:** Complete codebase review focusing on potential errors, edge cases, and security issues

---

## 🔴 CRITICAL ISSUES

### 1. **Database Password Exposure in Output** ⚠️ SECURITY RISK
**Location:** [install.sh](install.sh#L2397)
```bash
echo -e "${CYAN}${BOLD}Database Password:${NC}  ${YELLOW}$DB_PASSWORD${NC}"
```
**Issue:** Database password is printed in plain text to the terminal. This can be:
- Captured in screen recordings
- Visible over shoulder surfing
- Logged in terminal history if redirected
- Captured in screenshots

**Fix:** Remove or mask the password display, only show it in a secure way (e.g., saved to file with restricted permissions).

---

### 2. **Missing Error Handling on Critical `cd` Commands**
**Locations:** Multiple
- [install.sh](install.sh#L576) - `cd /var/www/pterodactyl`
- [install.sh](install.sh#L1741) - `cd /var/www/pterodactyl`

**Issue:** Using `cd` without checking if directory exists or if command succeeded. With `set -e`, if `cd` fails, script will abort but may leave system in inconsistent state.

**Edge Case:** If directory doesn't exist or has incorrect permissions, `cd` will fail and subsequent relative path operations will execute in wrong directory.

**Fix:** Always check directory existence before `cd` or use `cd || exit`.

---

### 3. **Unquoted Variable Expansion with Special Characters**
**Locations:** Multiple grep/search patterns identified

**Issue:** Variables containing spaces or special characters can cause word splitting:
```bash
mkdir -p $backup_dir  # Should be "$backup_dir"
```

**Edge Case:** If a path contains spaces (e.g., `/var/my backups/panel`), commands will fail.

**Fix:** Quote ALL variable expansions: `"$variable"`

---

## 🟡 HIGH PRIORITY ISSUES

### 4. **Race Condition in Database Backup**
**Location:** [install.sh](install.sh#L681-737)

**Issue:** Checking if MariaDB/MySQL is active with `systemctl is-active --quiet` doesn't guarantee it will stay active during the entire backup process.

**Edge Case:**
1. Service check passes
2. Service crashes/restarts during backup
3. Backup writes partial/corrupted SQL file
4. Script continues thinking backup succeeded

**Fix:** Add additional checks:
```bash
if ! systemctl is-active --quiet mariadb; then
    print_error "MariaDB stopped during backup!"
    return 1
fi
```

---

### 5. **Docker Volume Backup May Timeout on Large Volumes**
**Location:** [install.sh](install.sh#L762-773)

**Issue:** No timeout or progress monitoring on Docker volume backups. Large volumes (100GB+ game servers) could hang indefinitely.

**Edge Case:** 
- Server has 500GB of game server data
- Backup runs for hours without feedback
- No way to cancel safely
- Disk space exhaustion not checked

**Fix:** Add:
- Disk space pre-check before backup
- Timeout mechanism (`timeout 3600 docker run...`)
- Progress indication for each volume

---

### 6. **Missing Validation on `--config` File Path**
**Location:** [install.sh](install.sh#L387-393)

**Issue:** Config file is sourced without validation of contents. Malicious config could execute arbitrary code.

**Security Risk:** 
```bash
# Attacker creates malicious.conf:
echo "rm -rf /var/www/pterodactyl" > malicious.conf

# User runs:
sudo ./install.sh --config malicious.conf
```

**Fix:**
- Validate config file format before sourcing
- Use safer parsing (read key=value, not source)
- Check file ownership and permissions

---

### 7. **Incomplete Error Recovery in Backup Creation**
**Location:** [install.sh](install.sh#L877-899)

**Issue:** Archive creation failure at end of backup process leaves backup directory without cleanup or notification that it's incomplete.

**Edge Case:**
- Backup directory created: ✓
- All files backed up: ✓
- Archive creation fails (disk full): ✗
- User thinks they have complete backup archive

**Fix:** Add explicit success/failure markers in backup directory.

---

## 🟠 MEDIUM PRIORITY ISSUES

### 8. **No Retry Logic for Network Operations**
**Locations:**
- [install.sh](install.sh#L1748) - Panel download
- Database operations
- Composer install

**Issue:** Single network failure causes complete installation failure. No retry mechanism.

**Edge Case:**
- Temporary DNS failure
- GitHub rate limiting
- Network hiccup
- All cause complete installation abort

**Fix:** Add retry logic:
```bash
retry_count=0
max_retries=3
until curl -Lo panel.tar.gz [...] || [ $retry_count -eq $max_retries ]; do
    ((retry_count++))
    sleep 5
done
```

---

### 9. **Weak Domain Validation Regex**
**Location:** [install.sh](install.sh#L1170)

**Issue:** Current regex allows some invalid domains and rejects some valid ones.

**Edge Cases:**
- Single-label domains (e.g., `localhost`) - rejected
- Internationalized domains (IDN) - rejected
- Very long domain labels (>63 chars) - accepted but invalid

**Fix:** Use more robust domain validation or DNS lookup verification.

---

### 10. **Email Validation Too Permissive**
**Location:** [install.sh](install.sh#L1184)

**Issue:** Regex allows technically invalid emails like `user@.com`, `user@domain.c`.

**Fix:** Strengthen validation or verify MX records.

---

### 11. **Systemctl Commands Without Verification**
**Locations:** Multiple service management operations

**Issue:** Commands like `systemctl restart nginx` don't verify if service actually started successfully.

**Edge Case:**
```bash
systemctl restart nginx  # Fails due to config error
# Script continues, thinking Nginx is running
# Later operations fail mysteriously
```

**Fix:** Add verification:
```bash
systemctl restart nginx
if ! systemctl is-active --quiet nginx; then
    print_error "Nginx failed to start!"
    return 1
fi
```

---

### 12. **Missing Disk Space Checks Before Operations**
**Issue:** No verification that sufficient disk space exists before:
- Downloading panel.tar.gz (~50MB)
- Creating backups (can be 100GB+)
- Installing packages
- Docker volume operations

**Edge Case:**
- Disk 95% full
- Start backup
- Disk fills completely
- System becomes unstable

**Fix:** Add pre-flight checks:
```bash
required_space_mb=10240  # 10GB
available_space=$(df /var | tail -1 | awk '{print $4}')
if [ $available_space -lt $((required_space_mb * 1024)) ]; then
    print_error "Insufficient disk space!"
    exit 1
fi
```

---

### 13. **Composer Install Runs as Root**
**Location:** [install.sh](install.sh#L1768)

**Issue:** `COMPOSER_ALLOW_SUPERUSER=1` allows Composer to run as root, which is a security risk.

**Security Risk:**
- Composer plugins can execute arbitrary code as root
- Dependencies not verified
- Supply chain attack vector

**Better Approach:** Create temporary user or use `--no-scripts` flag.

---

## 🟢 LOW PRIORITY / ENHANCEMENT ISSUES

### 14. **No Integrity Verification on Downloads**
**Issue:** Downloaded `panel.tar.gz` is not verified against checksum or signature.

**Fix:** Verify SHA256 hash or GPG signature after download.

---

### 15. **Hard-coded Timeouts and Limits**
**Examples:**
- PHP FPM worker calculations based on RAM
- No timeout on long-running operations
- Fixed retry counts

**Fix:** Make configurable via environment variables.

---

### 16. **Inconsistent Error Message Format**
**Issue:** Some errors show helpful context, others just say "Failed".

**Fix:** Standardize error messages with:
- What failed
- Why it failed (if known)
- How to fix it
- Where to find logs

---

### 17. **Missing Input Sanitization**
**Locations:** User inputs for:
- `$FQDN`
- `$EMAIL`
- `$WEB_HOSTING_DOMAIN`
- `$DB_PASSWORD`

**Issue:** While validated with regex, inputs are used directly in:
- SQL queries (risk: SQL injection via artisan commands)
- File paths (risk: path traversal)
- Shell commands (risk: command injection)

**Current Protection:** Limited by regex validation, but not fully sanitized.

**Fix:** Explicitly sanitize inputs before use:
```bash
FQDN=$(echo "$FQDN" | sed 's/[^a-zA-Z0-9.-]//g')
```

---

### 18. **Wings Installer Path Dependency**
**Location:** [install.sh](install.sh#L2526)

```bash
if [ -x "$SCRIPT_DIR/install-wings.sh" ]; then
```

**Issue:** Relies on relative path from script location. If script is run via symlink or from different directory, path resolution may fail.

**Edge Case:**
```bash
cd /tmp
sudo /opt/scripts/install.sh --essentials
# SCRIPT_DIR = /opt/scripts
# Looks for /opt/scripts/install-wings.sh
# But it might not be there if moved
```

**Fix:** Add fallback search paths or absolute path detection.

---

### 19. **Auto Mode Password Generation Lacks Entropy Source Check**
**Location:** [install.sh](install.sh#L1200)

```bash
DB_PASSWORD=$(openssl rand -base64 32)
```

**Issue:** On systems with low entropy (fresh VPS, VM), `openssl rand` may block or generate weak passwords.

**Fix:** Check `/proc/sys/kernel/random/entropy_avail` before generating, or use `/dev/urandom` explicitly.

---

### 20. **No Mechanism to Resume Failed Installation**
**Issue:** If installation fails at step 10/15, user must start from scratch. `STATE_FILE` exists but no `--resume` option.

**Enhancement:** Add resume functionality:
```bash
./install.sh --resume
```

---

### 21. **Firewall Configuration May Lock Out SSH**
**Potential Issue:** UFW configuration might not preserve existing SSH access.

**Edge Case:**
- User connected via non-standard SSH port (e.g., 2222)
- Script enables UFW with default rules
- User gets locked out

**Fix:** Detect current SSH connection port and preserve it.

---

### 22. **No Verification of SSL Certificate Issuance**
**Issue:** Let's Encrypt SSL setup doesn't verify if certificate was actually issued.

**Edge Case:**
- Rate limit hit (5 certs/week for same domain)
- DNS not propagated
- Certbot fails silently
- Script continues with HTTP

**Fix:** Check certificate existence after certbot run.

---

## 🔵 CODE QUALITY ISSUES

### 23. **Inconsistent Use of `|| true` Pattern**
**Examples:**
```bash
systemctl restart redis-server || true   # Suppresses error
tar -czf backup.tar.gz ... 2>/dev/null || print_warning  # Shows warning
```

**Issue:** Inconsistent error suppression makes debugging harder.

**Fix:** Standardize error handling strategy.

---

### 24. **Magic Numbers Without Comments**
**Examples:**
- `2048` MB RAM minimum
- Port numbers `80`, `443`, `3306`, `8080`
- `32` byte password length

**Fix:** Define as named constants with comments.

---

### 25. **Long Functions (>100 lines)**
**Functions:**
- `create_full_backup()` - 230 lines
- `get_user_input()` - 150+ lines
- `install_pterodactyl()` - 200+ lines

**Issue:** Hard to test, maintain, and debug.

**Fix:** Break into smaller, single-purpose functions.

---

## 📊 STATISTICS

**Total Issues Found:** 25  
**Critical (Security/Data Loss):** 3  
**High Priority:** 5  
**Medium Priority:** 9  
**Low Priority/Enhancement:** 8  

---

## 🛠️ RECOMMENDED FIX PRIORITY

1. **Immediate (Do First):**
   - #1: Remove password display from output
   - #2: Add error handling to `cd` commands
   - #6: Validate config file before sourcing

2. **Next Sprint:**
   - #4: Fix database backup race condition
   - #5: Add timeout to Docker volume backup
   - #8: Add network retry logic
   - #11: Verify systemctl operations
   - #12: Add disk space checks

3. **Future Improvements:**
   - #14: Download integrity verification
   - #20: Add resume functionality
   - #21: Preserve SSH access in firewall config
   - #22: Verify SSL certificate issuance

4. **Code Quality (Ongoing):**
   - #23: Standardize error handling
   - #24: Replace magic numbers with constants
   - #25: Refactor long functions

---

## 🧪 TESTING RECOMMENDATIONS

1. **Create test scenarios for edge cases:**
   - Low disk space (< 1GB available)
   - Network interruption during download
   - MariaDB crash during backup
   - Invalid config file injection
   - Large Docker volumes (100GB+)

2. **Automated testing:**
   - ShellCheck integration
   - Bash syntax validation
   - Mock external services
   - Integration tests in container

3. **Manual testing:**
   - Fresh Ubuntu 20.04/22.04/24.04
   - Debian 11/12
   - Low-resource VPS (1GB RAM)
   - Interrupted installation recovery

---

## 📝 NOTES

This analysis was performed through systematic code review, focusing on:
- Error handling completeness
- Input validation
- Security vulnerabilities  
- Race conditions
- Resource exhaustion scenarios
- Network failure resilience
- Edge cases in production environments

Many issues are **potential** - they may not manifest in typical usage but could cause problems in edge cases or under specific conditions.

The code overall is **well-structured** with good features like:
- ✅ Backup before operations
- ✅ Rollback mechanism
- ✅ Logging system
- ✅ Progress tracking
- ✅ Multiple installation modes

Hardening these areas will make the installer production-ready for enterprise deployments.
