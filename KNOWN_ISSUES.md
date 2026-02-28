# Known Issues & Edge Cases

This document covers known limitations, edge cases, and design decisions for the Nihongo Vocab Test application.

## Known Limitations

### 1. No Persistent State

**Issue:** Tests are not saved. Each time you request a test, a new one is generated from scratch.

**Why:** The application is designed as stateless to keep the NAS storage minimal and deployment simple. This is intentional for a personal learning tool where repeated practice is beneficial.

**Workaround:** 
- Tests can be exported by copying the browser data or using print-to-PDF
- Consider implementing a database if you need persistent scoring history

**Future Enhancement:** Add optional MongoDB/SQLite integration for test history tracking.

---

### 2. Single User / No Authentication

**Issue:** No login system. Anyone on your Tailscale network can access the app.

**Why:** Tailscale VPN provides network-level security. Additional auth is unnecessary for personal use on a private VPN.

**If You Need Authentication:**
1. Add basic auth via FastAPI middleware
2. Or use Tailscale policy ACLs to restrict access

---

### 3. Vocabulary Files Must Be Exact Format

**Issue:** Excel files must have specific structure:
- Column A: Kanji (日本語)
- Column B: Kana (ひらがな)
- Column C: English translation

**Why:** The `generate_test.py` script expects this exact layout.

**What Happens if Format is Wrong:**
- 500 errors when generating tests
- "IndexError: list index out of range" in logs

**Fix:**
1. Open `resources/vocabulary_N4.xlsx` in Excel
2. Verify column structure matches expected format
3. Or modify `generate_test.py` line ~30 to match your file format

---

### 4. Limited Vocabulary File Size

**Issue:** Files larger than ~50MB may cause performance issues.

**Why:** The entire file is loaded into memory when generating tests.

**Current File Sizes:**
- vocabulary_N4.xlsx: ~312KB ✓
- vocabulary_N5.xlsx: ~240KB ✓

**If You Expand to N3/N2/N1:**
- Consider splitting into smaller files
- Or optimize by loading only recent entries

---

### 5. iPhone Browser Limitations

**Issue:** Some older browsers may not fully support the responsive design.

**Affected Browsers:**
- Safari iOS < 11 (very old)
- Chrome iOS < 50 (very old)

**Modern Browsers (All Supported):**
- Safari iOS 11+
- Chrome iOS 50+
- Firefox iOS
- Edge iOS

---

### 6. Tailscale Custom Domain Requires Active Subscription

**Issue:** Custom domain features like `nihongo.your-domain.ts.net` require Tailscale Premium.

**Tailscale Free Tier Limitations:**
- No custom domain (but direct IP access works)
- Direct connection: `https://[machine-name].ts.net`

**Workaround for Free Tier:**
- Access via direct IP: `https://192.168.x.x:8500` (if you expose via port forward)
- Or upgrade to Tailscale Premium ($60/user/year)

---

## Edge Cases

### 1. Empty Vocabulary Set Selected

**Issue:** If all vocabulary words are marked as "answered correctly" or filtered out, empty test is generated.

**Symptoms:**
- Blank test page
- No questions displayed

**Fix:**
1. Reset vocabulary progress (requires database)
2. Or regenerate vocabulary with all words

---

### 2. Special Characters in Vocabulary

**Issue:** Some vocabulary may contain rare kanji, particles, or punctuation.

**Examples:**
- Ruby text (小書き) - `1年(いちねん)`
- Multiple readings - `生きる/生かす`
- Punctuation - `です、ある！`

**Current Behavior:** Handled correctly - the app displays them as-is.

**Potential Issue:** Terminal/console output may not display correctly if logs are viewed on systems without proper Unicode support.

---

### 3. Network Interruption During Test

**Issue:** If your iPhone loses VPN connection mid-test, submitted answer may not process.

**Symptoms:**
- "Connection refused" error mid-way
- Answer submitted but not confirmed

**Current Behavior:** No auto-save, answer is lost.

**Workaround:** 
- Reconnect to Tailscale
- Refresh browser
- Test is re-generated fresh

**Future Enhancement:** Implement client-side cache with sync when reconnected.

---

### 4. Very Fast Test Completion

**Issue:** If you complete a test in under 1 second (impossible to do honestly), it may trigger rate limiting or validation rules.

**Current Behavior:** No rate limiting implemented - this is not a real concern for a personal app.

---

### 5. Concurrent Access from Multiple Devices

**Issue:** If you access the app from multiple devices simultaneously, each gets independent test sessions.

**Current Behavior:** Each device gets its own fresh test - no conflicts.

**Potential Future Issue:** If you add scoring persistence, concurrent writes may cause race conditions.

**Recommendation:** If adding persistence, implement proper locking or document "single session per user" requirement.

---

### 6. Very Large Vocabulary Sets (1000+ words)

**Issue:** Generating tests with 1000+ vocabulary items may take several seconds.

**Performance Numbers:**
- N5 (240 words): ~50ms to generate test
- N4 (300+ words): ~100ms to generate test
- Custom large set (1000+ words): ~500-1000ms

**User Impact:**
- Test appears "Loading..." for 1+ second
- Not a blocker, but noticeable

**Fix:** 
- Use sampling: randomly select 30 questions from 1000 word list
- Current implementation already does this

---

## Browser/Device Compatibility

### Tested & Working

✅ iOS Safari 15+
✅ Chrome (iOS, Android, Desktop)
✅ Firefox (Desktop)
✅ Edge (Desktop, iOS)

### Known Issues

⚠️ Internet Explorer - Not supported (EOL)
⚠️ Very old Android browsers - May have CSS compatibility issues

### Touch/Mobile Specific

✅ Touch keyboard appears automatically
✅ Form input focus works correctly
✅ Pinch-to-zoom disabled (prevents accidental zoom)
✅ Landscape orientation supported

---

## Docker/NAS Specific Issues

### 1. Out of Disk Space

**Issue:** If `/volume1/docker` runs out of space, Docker won't start.

**Symptoms:**
```
No space left on device
```

**Fix:**
```bash
# Check disk usage
ssh nas "df -h"

# Clean up old Docker images/containers
ssh nas "docker system prune -a"
```

---

### 2. Memory Pressure

**Issue:** NAS with limited RAM (< 512MB available) may struggle with Docker.

**Symptoms:**
- Container exits unexpectedly
- "OOMKilled" in logs

**Fix:**
```bash
# Check memory
ssh nas "free -h"

# Reduce other services or add RAM if possible
```

---

### 3. Slow Network During Deployment

**Issue:** Initial Docker build and push to NAS takes time on slow networks.

**Typical Times:**
- Fast network (>10Mbps): 2-3 minutes
- Slow network (<1Mbps): 15+ minutes

**Not an issue:** The deployment script handles this automatically.

---

## Data Integrity Issues

### 1. Vocabulary File Corruption

**Issue:** If Excel file gets corrupted, app won't start.

**Symptoms:**
```
Error reading Excel file: file appears to be a text file
```

**Recovery:**
```bash
# Verify file
ssh nas "file resources/vocabulary_N4.xlsx"

# Should show: "Microsoft Excel 2007+ XML"
# If not, restore from backup or regenerate
```

---

### 2. Partial File Upload

**Issue:** If vocabulary file upload interrupted, file is incomplete.

**Prevention:** Always verify file after upload:
```bash
ssh nas "python3 -c \"import openpyxl; wb = openpyxl.load_workbook('/path/to/file.xlsx'); print(f'{len(wb.active.rows)} rows')\""
```

---

## Tailscale-Specific Edge Cases

### 1. DNS Not Resolving Custom Domain

**Symptoms:**
```
Failed to resolve nihongo.your-domain.ts.net
```

**Causes:**
- DNS hasn't propagated yet (wait 5-10 minutes)
- Tailscale daemon not running on NAS
- DNS cache needs refresh

**Fix:**
```bash
# Restart Tailscale on NAS
ssh nas "sudo systemctl restart tailscaled"

# Clear local DNS cache (macOS)
dscacheutil -flushcache

# Clear local DNS cache (Linux)
sudo systemctl restart systemd-resolved
```

---

### 2. Tailscale Subnet Router Conflicts

**Issue:** If NAS is also a subnet router, custom domain may not work correctly.

**Solution:** Use direct IP or disable subnet routing for this machine in Tailscale console.

---

### 3. Funnel Exposure (If Enabled)

**Issue:** If you enable Tailscale Funnel for public access, your app becomes publicly accessible.

**Security Risk:** 
- Anyone on the internet can access your vocabulary app
- No authentication required

**Recommendation:** 
- Only enable Funnel if you want public access
- Consider adding authentication first
- Or use IP allowlists in Tailscale policy

---

## SSH Key Issues

### 1. Key Changed on NAS

**Issue:** If NAS user key is regenerated, your SSH key won't work.

**Symptoms:**
```
Permission denied (publickey)
```

**Fix:**
```bash
./setup-ssh.sh
```
This will update the key.

---

### 2. Multiple SSH Keys

**Issue:** If you have multiple SSH keys, wrong one might be used.

**Fix:** Ensure `.ssh/config` specifies correct key:
```
Host nas
    IdentityFile ~/.ssh/id_ed25519
```

---

## Performance Considerations

### 1. First Load Delay

**Issue:** First test generation after container start may be slow.

**Why:** Python modules loading, Excel file reading from disk.

**Expected:** 
- Cold start: 1-2 seconds
- Subsequent: 100-200ms

**Not a Problem:** Normal behavior.

---

### 2. Vocabulary File Caching

**Note:** The current implementation reads the Excel file fresh for each test.

**Optimization Opportunity:** Cache vocabulary in memory between requests.

**Current Trade-off:** Simple implementation vs. slight performance cost.

---

## Future Enhancements (Out of Scope for Current Version)

- [ ] Persistent test history with MongoDB/SQLite
- [ ] User authentication and per-user progress
- [ ] Vocabulary sorting/filtering options
- [ ] Detailed statistics and charts
- [ ] Mobile app (instead of web)
- [ ] Offline support (PWA)
- [ ] Multi-language interface
- [ ] Advanced question types (listening, writing)

---

## Testing Notes

### Manual Testing Checklist

- [ ] Generate N4 test successfully
- [ ] Generate N5 test successfully
- [ ] Submit correct answer - score increases
- [ ] Submit wrong answer - explained
- [ ] Complete test - final score shown
- [ ] Refresh browser - new test generated
- [ ] Access from iPhone via Tailscale
- [ ] Access from desktop via Tailscale
- [ ] Landscape and portrait orientation work
- [ ] Network interruption and reconnect

### Not Tested (Limitations)

- [ ] Concurrent access from 100+ users (not designed for this)
- [ ] Vocabulary files > 10MB (not tested)
- [ ] Network latency > 1 second (may have UX issues)

---

## Support & Reporting

If you encounter issues not listed here:

1. Check `TROUBLESHOOTING.md` for common problems
2. Run `./verify-deployment.sh` to identify configuration issues
3. Collect logs: `./nas-commands.sh logs --tail=100 > debug.txt`
4. Report on GitHub with:
   - Error message and logs
   - Steps to reproduce
   - NAS model and OS version
   - Network setup (Tailscale, etc.)

