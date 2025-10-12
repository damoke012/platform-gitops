# Session 006: Next Steps

## Issue to Debug: CVE Email Not Sending

**Status**: Webhook receiving events (HTTP 200) but no email sent

### Troubleshooting Steps for Tomorrow

1. **Check CVE reporter logs with more detail:**
    ```bash
    oc logs -n harbor -l app=cve-reporter --tail=100

2. Check if SMTP secret has the correct password:
oc get secret smtp-secret -n harbor -o jsonpath='{.data.password}' | base64 -d
echo ""
3. Check Python script for errors:
# Check if webhook_receiver.py has print statements
oc exec -n harbor deployment/cve-reporter -- cat /scripts/webhook_receiver.py | grep -A 5 "def send_email"
4. Test SMTP connectivity from pod:
oc exec -n harbor deployment/cve-reporter -- python3 -c "
import smtplib
server = smtplib.SMTP('smtp-mail.outlook.com', 587)
server.starttls()
server.login('damoke012@hotmail.com', 'YOUR_PASSWORD')
print('SMTP connection successful')
server.quit()
"
5. Check if scan found Critical/High CVEs:
oc run check-cves --image=curlimages/curl -n harbor --rm -i --restart=Never -- \
  curl -s -u "admin:Harbor12345" \
  "http://harbor:80/api/v2.0/projects/library/repositories/cve-reporter/artifacts/1.0.0" | grep -A 10 scan_overview
6. Add debug logging to webhook receiver:
  - The Python script might be failing silently
  - Need to check Harbor API response
  - Verify email sending logic

Likely Issues

1. SMTP Password: May need app-specific password for Outlook
2. No Critical/High CVEs: Script only sends if Critical or High found
3. Python Exception: Script catching errors but not logging them
4. Harbor API Response: May not be getting scan results correctly

Quick Fix Options

- Update webhook_receiver.py to add more logging
- Test email sending separately
- Check if Outlook requires app password instead of regular password

---
Main Focus for Session 006

After fixing email, proceed to:
- CI/CD Pipeline setup (Tekton/Jenkins)
- Build → Scan → Test → Deploy workflow
- Integration with ArgoCD

