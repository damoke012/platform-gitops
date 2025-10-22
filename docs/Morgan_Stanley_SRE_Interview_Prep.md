# Morgan Stanley - Senior Site Reliability Engineer, VP, P5 Interview Preparation Guide

## Table of Contents
1. [Role Overview & Key Expectations](#role-overview--key-expectations)
2. [Technical Deep Dive Areas](#technical-deep-dive-areas)
3. [Leadership & Communication](#leadership--communication)
4. [Production Support & Incident Management](#production-support--incident-management)
5. [Automation & DevOps Practices](#automation--devops-practices)
6. [Financial Services Domain Knowledge](#financial-services-domain-knowledge)
7. [Behavioral Questions & STAR Method Examples](#behavioral-questions--star-method-examples)
8. [Questions to Ask Interviewers](#questions-to-ask-interviewers)
9. [Morgan Stanley Culture & Values](#morgan-stanley-culture--values)

---

## Role Overview & Key Expectations

### Position Summary
- **Level**: VP, P5 (Senior/Principal level)
- **Team**: Wealth Management (WM) Product Technology
- **Primary Focus**: Production reliability, automation, minimizing outages, 24/7 support coverage
- **Experience Required**: 10+ years in production environments, preferably financial IT

### Critical Success Factors
1. **Zero tolerance for production outages** - proactive monitoring and prevention
2. **Automation-first mindset** - eliminate TOIL (Toil: manual, repetitive operational work)
3. **Bridge between Dev and Ops** - strong collaboration with development teams
4. **24/7 accountability** - weekend on-call rotation and offshore coordination
5. **VP-level leadership** - subject matter expert, influencing teams, driving initiatives

---

## Technical Deep Dive Areas

### 1. Programming & Scripting (Critical Skill)

#### Languages to Discuss
- **Python**: Automation scripts, API integrations, data processing
- **Shell/Bash**: System administration, deployment automation, log parsing
- **Perl**: Legacy systems support (common in financial services)
- **Additional**: Ruby, Java, C# (mention if experienced)

#### Prepare to Discuss
- **Real-world automation examples**:
  - "I automated deployment validation using Python, reducing deployment time from 4 hours to 30 minutes"
  - "Built a shell script framework for log aggregation across 200+ servers"
  - "Created Python-based health check monitors that reduced MTTD by 60%"

- **Code quality & best practices**:
  - Version control (Git), code reviews
  - Error handling, logging, idempotency
  - Testing automation scripts (unit tests, integration tests)

#### Sample Technical Question Prep
**Q: "How would you automate deployment validation across multiple environments?"**

**A**: "I'd create a Python framework with these components:
1. Configuration management (YAML/JSON for environment-specific parameters)
2. Pre-deployment checks (dependency validation, health checks, backup verification)
3. Deployment execution with rollback capability
4. Post-deployment validation (smoke tests, API health checks, log analysis)
5. Notification system (Slack/email with deployment status)
6. Audit logging for compliance

I'd use libraries like `paramiko` for SSH, `requests` for API calls, and `pytest` for validation tests. The framework would integrate with Jenkins/Train for CI/CD orchestration."

---

### 2. Database Technologies (Strong Requirement)

#### Platforms to Master
- **DB2**: IBM's enterprise database (common in banking)
- **Sybase**: Legacy systems in financial services
- **Oracle**: Enterprise applications, PL/SQL

#### Key Competencies
**Performance Tuning**:
- Query optimization (execution plans, indexing strategies)
- Lock contention analysis and resolution
- Connection pooling configuration
- Database statistics and maintenance

**Troubleshooting Scenarios**:
- "Application slowness" → Check: long-running queries, blocking locks, resource contention
- "Connection failures" → Check: connection pool exhaustion, network issues, max connections limit
- "Data inconsistencies" → Check: transaction isolation levels, replication lag

**Production Support Skills**:
```sql
-- Quick diagnostic queries to know
-- Check active sessions and blocking
SELECT * FROM sysprocesses WHERE blocked > 0;

-- Identify expensive queries
SELECT TOP 10 * FROM sys.dm_exec_query_stats
ORDER BY total_worker_time DESC;

-- Monitor locks
SELECT * FROM sys.dm_tran_locks WHERE resource_type = 'OBJECT';
```

#### Sample Question Prep
**Q: "Production is experiencing database slowness. Walk me through your troubleshooting approach."**

**A**: "My systematic approach:
1. **Immediate triage**: Check monitoring dashboards (CPU, I/O, memory, connection count)
2. **Active session analysis**: Identify long-running queries, blocking chains
3. **Resource verification**: Tablespace/disk space, lock escalation, wait events
4. **Query analysis**: Review execution plans for recent deployments or unusual queries
5. **Application layer**: Connection pool health, query patterns from app logs
6. **Communication**: Update stakeholders with findings and ETA
7. **Mitigation**: Kill blocking sessions if appropriate, restart connection pools, query optimization
8. **Post-incident**: RCA with developers, add monitoring for early detection, index optimization"

---

### 3. Job Scheduling - Autosys (Essential)

#### Core Knowledge
**Autosys Architecture**:
- Job types: Command, File Watcher, Box (container job)
- Conditions: date/time, dependencies, file triggers
- Job states: SUCCESS, FAILURE, RUNNING, TERMINATED
- Calendar management for business day scheduling

**Production Support Skills**:
- **Dependency troubleshooting**: "Job didn't run" → Check upstream dependencies, hold/ice status
- **Job monitoring**: Real-time status tracking, alerts for failures
- **Schedule optimization**: Reducing job runtime, parallel execution strategies
- **Change management**: JIL (Job Information Language) updates, testing in non-prod

**Common Issues & Resolutions**:
| Issue | Root Cause | Resolution |
|-------|------------|------------|
| Job stuck in RUNNING | Process hung/crashed | Check process status, kill if needed, restart job |
| Job not starting | Dependencies not met | Verify upstream job status, check conditions |
| Job failure | Script errors, resource issues | Review logs, verify permissions/resources |
| Performance degradation | Resource contention | Reschedule jobs, optimize scripts, add capacity |

#### Sample Question Prep
**Q: "A critical EOD batch job failed at 2 AM. How do you handle it?"**

**A**: "Immediate response protocol:
1. **Assess impact**: Check downstream dependencies, identify affected business processes
2. **Initial investigation**: Review job logs, error messages, resource availability
3. **Communication**: Alert on-call manager and affected business units with initial findings
4. **Quick fix attempt**: If it's a known issue (disk space, network), resolve and rerun
5. **Escalation decision**: If complex (data issue, code bug), engage development team
6. **Workaround**: If fix takes time, explore manual processing or skip-and-reprocess options
7. **Monitoring**: Watch job completion, validate outputs
8. **Documentation**: Update incident ticket, prepare RCA for morning review
9. **Prevention**: Propose pre-checks, resource monitoring, early alerting"

---

### 4. Messaging Systems - MQ (Message Queue)

#### IBM MQ / WebSphere MQ Knowledge
**Architecture Components**:
- Queue Managers: Control and manage queues
- Queues: Local, remote, transmission, dead-letter
- Channels: Sender, receiver, server-connection
- Clusters: High availability and load balancing

**Troubleshooting Techniques**:
- **Message stuck in queue**: Check consumer status, message properties, poison messages
- **Channel not running**: Verify network connectivity, certificates, channel definitions
- **Performance issues**: Queue depth monitoring, message size optimization
- **Security**: Channel authentication, user permissions, SSL/TLS configuration

**Monitoring & Alerts**:
```bash
# Common MQ commands to know
echo "DISPLAY QSTATUS(QUEUE.NAME) CURDEPTH" | runmqsc QMGR_NAME
echo "DISPLAY CHSTATUS(CHANNEL.NAME)" | runmqsc QMGR_NAME
echo "DISPLAY QMGR" | runmqsc QMGR_NAME
```

---

### 5. Web Services & APIs

#### Technologies & Protocols
- **REST APIs**: HTTP methods, status codes, authentication (OAuth, JWT, API keys)
- **SOAP**: WSDL, XML parsing, envelope structures
- **JSON/XML**: Data serialization, schema validation
- **API Gateways**: Rate limiting, routing, monitoring

#### Production Support Scenarios
**API Failure Troubleshooting**:
1. **Check connectivity**: Network, DNS, firewall rules
2. **Authentication**: Token expiration, certificate validity, credentials
3. **Request/Response analysis**: Payload validation, timeout settings
4. **Rate limiting**: Throttling, quota exceeded errors
5. **Endpoint health**: Service availability, deployment issues
6. **Version compatibility**: API versioning, breaking changes

**Monitoring & Alerting**:
- Response time thresholds
- Error rate spikes (4xx, 5xx)
- Throughput degradation
- Latency percentiles (p95, p99)

---

### 6. Operating Systems - UNIX/Linux/Windows

#### UNIX/Linux Deep Expertise (Primary Focus)

**System Administration**:
```bash
# Performance diagnostics commands to master
top/htop          # CPU and memory usage
iostat            # Disk I/O statistics
netstat/ss        # Network connections
vmstat            # Virtual memory statistics
df -h             # Disk space
du -sh            # Directory sizes
lsof              # Open files and network connections
strace            # System call tracing for debugging

# Log analysis
tail -f /var/log/app.log
grep -i error /var/log/messages
awk '{print $1}' access.log | sort | uniq -c | sort -rn  # IP frequency

# Process management
ps aux | grep java
kill -9 <PID>
nohup ./script.sh > output.log 2>&1 &
```

**File System & Permissions**:
- Understanding of ext4, xfs file systems
- NFS mounts troubleshooting
- Permission issues (chmod, chown, ACLs)
- Disk space management and cleanup

**Network Troubleshooting**:
```bash
ping, traceroute, telnet, nc (netcat)
tcpdump -i eth0 port 8080
curl -v https://api.endpoint.com
nslookup/dig for DNS issues
```

#### Windows Server (Secondary but Important)
- PowerShell scripting for automation
- Event Viewer log analysis
- IIS troubleshooting (if applicable)
- Windows services management
- Performance Monitor (perfmon)

---

### 7. Application Debugging & Troubleshooting

#### Log File Analysis Mastery

**Structured Approach**:
1. **Identify relevant logs**: Application, system, database, web server
2. **Time correlation**: Align logs from multiple sources to incident time
3. **Pattern recognition**: Error messages, stack traces, warnings preceding failures
4. **Filtering techniques**: grep, awk, sed for large files
5. **Tool usage**: Splunk queries, ELK stack, log aggregation platforms

**Example Splunk Queries**:
```spl
# Error rate over time
index=production sourcetype=application ERROR | timechart count

# Find root cause of specific incident
index=production earliest=-1h latest=now | search "transaction_id=12345" | table _time, log_level, message

# Identify slow transactions
index=production | search "response_time>5000" | stats count by service_name

# Error pattern analysis
index=production ERROR | rex field=_raw "(?<error_type>Exception: \w+)" | stats count by error_type
```

#### Stack Trace Analysis
- **Java**: Understanding heap dumps, thread dumps (jstack, jmap)
- **Python**: Traceback interpretation, memory profiling
- **Memory leaks**: Heap analysis, garbage collection tuning
- **Thread deadlocks**: Thread dump analysis, lock contention

---

### 8. Monitoring Tools - Splunk, IP Soft, Sockeye

#### Splunk (Log Analytics & Monitoring)

**Core Capabilities**:
- Real-time log aggregation and search
- Dashboard creation for business metrics
- Alerting and incident detection
- Correlation searches for security/reliability

**Advanced Usage**:
```spl
# Create alerts for production issues
index=production ERROR | stats count by host, error_type | where count > 10

# Business metrics monitoring
index=transactions | stats sum(amount) as total_revenue by product | sort -total_revenue

# Performance degradation detection
index=production | stats avg(response_time) as avg_rt by service | where avg_rt > 3000

# Anomaly detection
index=production | timechart span=5m count | predict count future_timespan=10
```

**Interview Talking Points**:
- "Built Splunk dashboards reducing MTTD from 15 minutes to 2 minutes"
- "Created correlation searches detecting cascading failures across microservices"
- "Automated incident response using Splunk webhooks to PagerDuty/ServiceNow"

#### IPsoft (AIOps Platform)
- Autonomous incident detection and remediation
- Intelligent automation for known issues
- Predictive analytics for proactive alerts
- Integration with ITSM tools (ServiceNow)

#### Sockeye (Application Performance Monitoring)
- Real-time transaction tracing
- Dependency mapping
- Bottleneck identification
- SLA monitoring

---

### 9. CI/CD & Deployment Automation

#### Continuous Integration

**Jenkins**:
- **Pipeline as Code**: Jenkinsfile (declarative/scripted)
- **Build automation**: Compilation, testing, artifact generation
- **Integration**: Git webhooks, Maven/Gradle, Docker
- **Distributed builds**: Master/slave architecture

**Sample Jenkinsfile**:
```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/repo/project.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
                junit 'target/test-reports/*.xml'
            }
        }
        stage('Deploy to QA') {
            steps {
                script {
                    sh './deploy.sh qa'
                }
            }
        }
        stage('Smoke Tests') {
            steps {
                sh 'python smoke_tests.py'
            }
        }
    }
    post {
        failure {
            emailext to: 'team@example.com', subject: 'Build Failed', body: "${BUILD_URL}"
        }
    }
}
```

#### Continuous Deployment

**Train / Windeploy** (Morgan Stanley specific tools):
- Automated deployment orchestration
- Environment promotion workflows
- Rollback capabilities
- Deployment validation gates

**Best Practices to Discuss**:
- **Blue-green deployments**: Zero-downtime releases
- **Canary releases**: Gradual rollout with monitoring
- **Feature flags**: Decouple deployment from release
- **Automated rollback**: Triggered by health checks
- **Deployment checklists**: Pre/post deployment validation

---

### 10. Cloud Technologies - Azure & AWS

#### Azure Services (Likely Primary at Morgan Stanley)

**Core Services**:
- **Compute**: Virtual Machines, App Services, AKS (Kubernetes)
- **Storage**: Blob Storage, Azure Files, Disk Storage
- **Networking**: VNet, Load Balancer, Application Gateway, ExpressRoute
- **Monitoring**: Azure Monitor, Application Insights, Log Analytics
- **Security**: Key Vault, Azure AD, Network Security Groups

**SRE-Relevant Skills**:
- **Infrastructure as Code**: ARM templates, Terraform, Bicep
- **Auto-scaling**: VM scale sets, app service scaling rules
- **Disaster Recovery**: Azure Site Recovery, geo-replication
- **Cost optimization**: Reserved instances, right-sizing, monitoring

#### AWS Services (Secondary)

**Key Services to Know**:
- **EC2**: Instance types, auto-scaling groups, AMIs
- **S3**: Object storage, lifecycle policies, versioning
- **RDS**: Managed databases, read replicas, backups
- **CloudWatch**: Metrics, logs, alarms, dashboards
- **IAM**: Roles, policies, least privilege access
- **VPC**: Subnets, security groups, NAT gateways

#### Cloud Security Concepts
- **Network segmentation**: Subnets, security groups, firewalls
- **Identity management**: Role-based access control (RBAC)
- **Encryption**: At-rest (disk encryption), in-transit (TLS)
- **Compliance**: Data residency, audit logging, regulatory requirements
- **Secret management**: Key vaults, certificate rotation

---

### 11. Containerization & Orchestration

#### Docker

**Core Concepts**:
- **Images**: Layered filesystem, Dockerfile best practices
- **Containers**: Lifecycle management, networking, volumes
- **Registry**: Artifact storage, image versioning
- **Optimization**: Multi-stage builds, layer caching, image size reduction

**Sample Dockerfile**:
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/health || exit 1
CMD ["python", "app.py"]
```

#### Kubernetes (Environment on Demand)

**Architecture**:
- **Pods**: Smallest deployable units
- **Deployments**: Declarative updates, rolling updates
- **Services**: Load balancing, service discovery
- **ConfigMaps/Secrets**: Configuration management
- **Persistent Volumes**: Stateful applications

**SRE Operations**:
```bash
# Common kubectl commands
kubectl get pods -n production
kubectl describe pod <pod-name>
kubectl logs <pod-name> -f
kubectl exec -it <pod-name> -- /bin/bash
kubectl scale deployment app --replicas=5
kubectl rollout status deployment/app
kubectl rollout undo deployment/app
```

**Troubleshooting Scenarios**:
- **Pods crashing**: Check logs, resource limits, liveness/readiness probes
- **Service unreachable**: Verify service/endpoint, network policies, ingress
- **Performance issues**: Resource requests/limits, HPA configuration, node capacity

---

### 12. Infrastructure as Code (IaC)

#### Terraform

**Core Concepts**:
- **State management**: Remote backend (Azure Storage, S3)
- **Modules**: Reusable infrastructure components
- **Providers**: Azure, AWS, etc.
- **Workspaces**: Environment separation

**Sample Azure VM Creation**:
```hcl
resource "azurerm_virtual_machine" "app_server" {
  name                  = "app-vm-${var.environment}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  vm_size               = "Standard_D2s_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "app-server"
    admin_username = var.admin_user
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

**Best Practices**:
- Version control for all IaC
- Code review process
- Plan before apply
- Automated testing (terratest)
- Modular design for reusability

---

## Leadership & Communication

### VP-Level Expectations

#### Technical Leadership
1. **Subject Matter Expert (SME)**:
   - Go-to person for production architecture questions
   - Mentor junior engineers, knowledge transfer
   - Technical decision-making authority
   - Architecture review participation

2. **Cross-Functional Influence**:
   - Partner with Dev managers on reliability improvements
   - Collaborate with Infrastructure teams on capacity planning
   - Work with Business Units to understand impact
   - Drive initiatives across multiple teams

3. **Strategic Thinking**:
   - Long-term reliability roadmap
   - Cost optimization strategies
   - TOIL reduction initiatives
   - Scalability planning

#### Communication Skills (Excellent Required)

**Stakeholder Management**:
- **During incidents**:
  - Clear, concise status updates (what happened, impact, ETA)
  - Appropriate technical depth for audience (executives vs. engineers)
  - Ownership and accountability mindset

- **Regular operations**:
  - Weekly service health reports
  - Capacity planning presentations
  - Post-incident reviews (blameless)
  - Project status updates

**Example Incident Communication**:
```
INITIAL UPDATE (within 15 mins):
"INCIDENT: WM Trading Platform - Latency Issue
Status: Investigating
Impact: Users experiencing 10-second delays in trade execution
Affected Services: Trade Order Service (500 users)
Next Update: 3:30 PM or significant change
Bridge: [conference line]"

UPDATE #2 (30 mins later):
"Root Cause Identified: Database connection pool exhausted
Action: Restarting app servers in rolling fashion (5 min ETA)
Mitigation: Manual trade processing available as backup
Expected Resolution: 4:00 PM"

RESOLUTION:
"RESOLVED: All services restored at 3:55 PM
Duration: 1 hour 15 minutes
Root Cause: Deployment introduced connection leak
Immediate Fix: Rollback to previous version
Prevention: Enhanced pre-production testing, connection monitoring alerts
Full RCA: Will be published by EOD tomorrow"
```

---

### Team Collaboration

#### Working with Development Teams

**Building Strong Partnerships**:
1. **Embed with dev teams**: Attend sprint planning, retrospectives
2. **Shift-left reliability**: Design reviews, code reviews for operational concerns
3. **Shared responsibility**: Developers participate in on-call rotation
4. **Feedback loops**: Operations insights drive development priorities

**Key Discussion Points**:
- "I established 'SRE office hours' where developers could consult on production readiness"
- "Implemented 'shadowing' program where devs joined on-call to understand production issues"
- "Created runbook templates with dev teams for new service launches"

#### Reducing Escalations to Dev Teams

**Strategies**:
1. **Comprehensive runbooks**: Step-by-step troubleshooting guides
2. **Automated diagnostics**: Scripts that gather evidence before escalation
3. **Knowledge base**: Searchable repository of past incidents
4. **Training**: Regular sessions with developers on common issues
5. **Self-service tools**: Dashboards, log queries, restart capabilities

**Escalation Criteria**:
- Code bugs requiring fixes
- Data corruption issues
- Unknown errors not in runbooks
- Performance issues requiring code optimization

---

## Production Support & Incident Management

### 24/7 Support Coverage

#### On-Call Rotation Management

**Best Practices**:
- **Rotation schedule**: Balanced workload, advance notice
- **Handoff process**: Status briefing, ongoing issues, upcoming changes
- **Escalation matrix**: When to engage senior engineers, managers, executives
- **On-call toolkit**: Access verification (VPN, systems, documentation)

**Interview Talking Points**:
- "Managed on-call rotation for 15-person team across 3 time zones"
- "Reduced on-call alert fatigue by 60% through better alerting thresholds"
- "Implemented 'follow-the-sun' model coordinating US, UK, and Singapore teams"

#### Weekend & Offshore Coordination

**Flexibility & Availability**:
- Weekend deployments and maintenance windows
- Coordinating with offshore teams (likely India, APAC)
- Time zone overlap for knowledge transfer
- Being reachable for critical escalations

**Example Scenario**:
"Weekend deployment at 2 AM Saturday:
- Pre-deployment checklist completed Friday
- Coordination meeting with offshore team (8 AM their time)
- Deployment execution with bridge line
- Post-deployment validation
- Handoff to next shift with status summary
- Remain on-call for any rollback scenarios"

---

### Incident Response Framework

#### Severity Levels & Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|---------------|------------|
| SEV1 | Complete outage, financial impact | Immediate | Executives, all hands |
| SEV2 | Partial outage, degraded performance | < 15 mins | Management, cross-teams |
| SEV3 | Minor issues, limited user impact | < 1 hour | Team lead notification |
| SEV4 | Informational, no immediate impact | Next business day | Standard ticketing |

#### Incident Management Process

**1. Detection & Alert**:
- Monitoring tools trigger alert
- Initial assessment (severity, scope)
- Page on-call engineer

**2. Triage & Communication**:
- Open incident bridge/war room
- Initial stakeholder notification
- Assign incident commander (for SEV1/2)

**3. Investigation**:
- Gather logs, metrics, traces
- Form hypothesis
- Test theories

**4. Mitigation**:
- Implement fix or workaround
- Validate resolution
- Monitor for stability

**5. Recovery**:
- Clear alerts
- Final stakeholder update
- Document timeline

**6. Post-Incident Review**:
- Blameless RCA
- Action items (monitoring, code fixes, process improvements)
- Follow-up tracking

---

### Root Cause Analysis (RCA)

#### Blameless Post-Mortem Template

**Incident Summary**:
- Date/Time, Duration, Severity
- Impact (users affected, revenue loss, SLA breach)

**Timeline**:
- Detection, Response, Mitigation, Resolution

**Root Cause**:
- Technical failure (what broke)
- Contributing factors (why it happened)

**Resolution**:
- Immediate mitigation
- Permanent fix

**Action Items**:
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| Add monitoring for X metric | SRE Team | 2024-11-01 | High |
| Code fix for Y issue | Dev Team | 2024-11-05 | High |
| Update runbook | On-call Eng | 2024-10-25 | Medium |

**Lessons Learned**:
- What went well
- What could be improved
- Preventive measures

---

### Service Level Objectives (SLOs)

#### Defining SLOs for WM Applications

**Common SLOs**:
- **Availability**: 99.9% uptime (43 minutes downtime/month)
- **Latency**: p95 < 500ms, p99 < 1s
- **Error Rate**: < 0.1% of requests
- **Throughput**: Support 10,000 transactions/minute

**Error Budget Management**:
- Monthly error budget = 1 - SLO (e.g., 0.1% for 99.9% SLO)
- Budget spent during incidents
- When budget exhausted: freeze feature releases, focus on reliability

**Interview Example**:
"In my previous role, I established SLOs for a trading platform:
- 99.95% availability during market hours (9:30 AM - 4 PM ET)
- p99 latency < 200ms for trade execution
- Zero data loss SLO

We tracked error budget weekly. When we burned 50% budget mid-month due to database issues, I worked with development to:
1. Pause new features
2. Implement database connection pooling fixes
3. Add capacity
4. Enhanced monitoring

We finished the month within budget and implemented preventive measures."

---

## Automation & DevOps Practices

### TOIL Reduction

#### What is TOIL?
**T**oil: **T**edious, **O**perational, **I**nterrupt-driven, **L**imited value work
- Manual deployments
- Log file reviews
- Manual service restarts
- Ticket processing without automation

#### Automation Opportunities

**1. Deployment Automation**:
```python
# Example: Automated deployment validation
import requests
import time

def validate_deployment(service_name, environment):
    health_url = f"https://{service_name}-{environment}.ms.com/health"

    # Check health endpoint
    for attempt in range(10):
        try:
            response = requests.get(health_url, timeout=5)
            if response.status_code == 200:
                health = response.json()
                if health['status'] == 'UP':
                    print(f"✓ {service_name} is healthy")
                    return True
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt+1}: {e}")
            time.sleep(10)

    print(f"✗ {service_name} failed health check")
    return False

def validate_metrics(service_name):
    # Check Splunk for errors
    # Validate transaction counts
    # Compare with baseline metrics
    pass
```

**2. Self-Healing Systems**:
- **Auto-restart**: Unhealthy services automatically restart
- **Auto-scaling**: Traffic spikes trigger capacity increase
- **Automated failover**: Database failover without manual intervention
- **Cleanup scripts**: Disk space management, log rotation

**3. Chatbots/Runbook Automation**:
- Slack/Teams chatbot for common requests
- "Restart service X in environment Y"
- Automated log retrieval
- Status queries without logging into systems

---

### Continuous Improvement Culture

#### Kaizen for SRE

**Regular Reviews**:
- **Weekly**: On-call review, alert analysis
- **Monthly**: TOIL metrics, automation wins, SLO tracking
- **Quarterly**: Architecture reviews, capacity planning

**Metrics to Track**:
- **MTTD** (Mean Time to Detect): How quickly we identify issues
- **MTTR** (Mean Time to Resolve): How quickly we fix issues
- **Change Failure Rate**: % of deployments causing incidents
- **Deployment Frequency**: Releasing more often with automation
- **TOIL Percentage**: % of time spent on manual work (target: < 50%)

**Example Improvements**:
"Over 6 months, I led automation initiatives that:
- Reduced deployment time from 4 hours to 30 minutes (90% reduction)
- Decreased MTTR from 45 minutes to 12 minutes (73% improvement)
- Eliminated 200+ manual tickets/month through self-service tools
- Improved availability from 99.5% to 99.95%"

---

### Capacity Planning

#### Proactive Capacity Management

**Data Collection**:
- Historical trends (CPU, memory, disk, network)
- Business growth projections
- Seasonal patterns (EOQ, holidays)
- New feature impact estimates

**Forecasting Models**:
```python
# Simple linear regression for capacity forecasting
import numpy as np
from sklearn.linear_model import LinearRegression

# Historical data: months vs transaction volume
months = np.array([1, 2, 3, 4, 5, 6]).reshape(-1, 1)
transactions = np.array([100000, 120000, 135000, 155000, 180000, 210000])

model = LinearRegression()
model.fit(months, transactions)

# Forecast next 6 months
future_months = np.array([7, 8, 9, 10, 11, 12]).reshape(-1, 1)
forecast = model.predict(future_months)

# Add 20% buffer for safety
capacity_needed = forecast * 1.2
```

**Planning Considerations**:
- Lead time for hardware/cloud resources
- Budget approval cycles
- Testing new capacity
- Gradual rollout vs. big bang

---

### Performance Optimization

#### Application Performance Tuning

**JVM Tuning** (for Java applications):
```bash
# Heap size optimization
-Xms4g -Xmx4g  # Set min and max heap to same value

# Garbage collection tuning
-XX:+UseG1GC   # G1 garbage collector
-XX:MaxGCPauseMillis=200  # Target pause time

# GC logging for analysis
-Xloggc:gc.log -XX:+PrintGCDetails
```

**Database Query Optimization**:
1. **Analyze execution plans**: Identify full table scans
2. **Add indexes**: Based on WHERE clauses and JOINs
3. **Rewrite queries**: Avoid subqueries, use JOINs efficiently
4. **Implement caching**: Redis/Memcached for frequent queries
5. **Connection pooling**: Optimize pool size (not too small, not too large)

**Network Optimization**:
- **Compression**: Enable gzip for API responses
- **CDN**: Static content delivery
- **Connection keep-alive**: Reduce TCP handshake overhead
- **Protocol upgrades**: HTTP/2 for multiplexing

---

## Financial Services Domain Knowledge

### Wealth Management Context

#### Business Understanding

**WM Product Technology Scope**:
- **Portfolio Management**: Investment tracking, performance reporting
- **Client Relationship Management**: Advisor tools, client portals
- **Trading Systems**: Order execution, settlement
- **Compliance & Reporting**: Regulatory requirements, audit trails
- **Data & Analytics**: Market data, client analytics

**Critical Business Periods**:
- **Market hours**: 9:30 AM - 4:00 PM ET (zero tolerance for outages)
- **End of Day (EOD)**: Batch processing for settlements, reports
- **End of Quarter/Year**: Heavy reporting, regulatory filings
- **Tax season**: Client tax documents, high volume

**Impact of Outages**:
- **Financial loss**: Missed trades, market opportunities
- **Regulatory risk**: Compliance violations, fines
- **Reputation damage**: Client trust, advisor productivity
- **Legal exposure**: Failed fiduciary duties

---

### Regulatory & Compliance

#### Key Regulations

**1. SOX (Sarbanes-Oxley)**:
- Change management controls
- Separation of duties
- Audit trails for all changes
- Access controls and reviews

**2. FINRA (Financial Industry Regulatory Authority)**:
- Transaction reporting accuracy
- System availability requirements
- Data retention (7 years for most records)

**3. SEC (Securities and Exchange Commission)**:
- Market data integrity
- Trade execution best practices
- Cybersecurity controls

#### Compliance in SRE Role

**Audit Trails**:
- All production changes logged
- Approval workflows enforced
- Emergency access tracking

**Access Controls**:
- Least privilege principle
- Regular access reviews
- MFA for production systems

**Data Security**:
- Encryption at rest and in transit
- PII/PCI data handling
- Data masking in non-production

**Change Management**:
- CAB (Change Advisory Board) approval
- Testing evidence required
- Rollback plans documented

---

### Risk Management

#### Change Risk Assessment

**Risk Matrix**:
| Change Type | Risk Level | Approval Required | Testing |
|-------------|------------|-------------------|---------|
| Emergency hotfix | High | CTO/VP | Post-deployment validation |
| Standard release | Medium | Dev Manager + SRE Lead | Full regression suite |
| Configuration change | Low | SRE Lead | Smoke tests |
| Infrastructure upgrade | High | Architecture + Security | Pilot environment first |

**Risk Mitigation**:
- **Gradual rollouts**: Canary → 25% → 50% → 100%
- **Feature flags**: Deploy code dark, enable gradually
- **Rollback readiness**: Tested rollback procedure, database backups
- **Communication**: All stakeholders informed of high-risk changes

---

## Behavioral Questions & STAR Method Examples

### STAR Method Template

**S**ituation: Set the context (1-2 sentences)
**T**ask: Your specific responsibility (1 sentence)
**A**ction: What YOU did (3-4 sentences, most important)
**R**esult: Measurable outcome (1-2 sentences)

---

### Example 1: Handling Production Outage

**Q: "Tell me about a time you resolved a critical production incident."**

**A**:

*Situation*: "At my previous company, our payment processing system went down during Black Friday, affecting $50K/minute in revenue. The system was completely unreachable, and our monitoring showed database connection errors."

*Task*: "As the on-call SRE, I was responsible for restoring service as quickly as possible and identifying root cause to prevent recurrence."

*Action*: "I immediately:
1. Opened a SEV1 incident bridge and notified executives
2. Checked database health - it was running but connection pool was exhausted
3. Analyzed application logs and found a recent deployment introduced a connection leak
4. Made the call to rollback the deployment within 10 minutes of detection
5. Validated service restoration and monitored for 30 minutes
6. Worked with the dev team to identify the code issue (missing connection.close() in error handling path)
7. Led a blameless post-mortem the next day"

*Result*: "Total downtime was 18 minutes, limiting revenue loss to $900K. We implemented connection pool monitoring alerts and code review checklist for database interactions. Similar incidents were prevented, and MTTR improved by 40% over next quarter."

---

### Example 2: Automation Initiative

**Q: "Give me an example of how you've reduced TOIL through automation."**

**A**:

*Situation*: "Our team was spending 15-20 hours per week manually deploying applications across 50+ servers. Each deployment required logging into servers, copying files, restarting services, and manual validation. This was error-prone and delayed releases."

*Task*: "I was tasked with reducing deployment time and eliminating manual errors while ensuring reliability."

*Action*: "I designed and implemented an automated deployment framework:
1. Created a Python orchestration tool that integrated with our Git repos and Jenkins
2. Implemented pre-deployment validation (dependency checks, disk space, service health)
3. Built parallel deployment capability using ThreadPoolExecutor to deploy to multiple servers
4. Added automatic rollback if post-deployment health checks failed
5. Integrated Slack notifications for deployment status
6. Created comprehensive logging and audit trails for compliance
7. Trained the team and created documentation"

*Result*: "Deployment time reduced from 4 hours to 25 minutes (94% reduction). Manual errors dropped to zero. Team TOIL reduced by 15 hours/week, allowing focus on reliability improvements. Deployment frequency increased from weekly to daily, accelerating feature delivery."

---

### Example 3: Cross-Team Leadership

**Q: "Describe a situation where you had to influence a team you didn't manage."**

**A**:

*Situation*: "Our production incidents were frequently caused by dev teams not following operational best practices. They weren't writing proper logging, health checks were minimal, and runbooks didn't exist. This resulted in lengthy troubleshooting and escalations."

*Task*: "I needed to change development culture to include operational concerns, without having direct authority over dev teams."

*Action*: "I took a collaborative approach:
1. Analyzed 6 months of incidents and quantified impact (120 hours/month MTTR)
2. Presented data to dev managers showing how operational excellence reduces on-call burden for their teams too
3. Proposed a 'production readiness checklist' and volunteered to help implement
4. Established 'SRE design review' - I attended dev team sprint planning to provide input early
5. Created a 'runbook template' and paired with developers to write first few
6. Started 'SRE office hours' where devs could get operational guidance
7. Invited dev team members to shadow on-call rotation to see production challenges firsthand"

*Result*: "Within 3 months, 80% of new services launched with complete runbooks and proper instrumentation. Escalations to dev teams decreased by 60%. Dev teams reported 40% reduction in their on-call pages. The program became standard practice across the organization."

---

### Example 4: Performance Optimization

**Q: "Tell me about a time you improved system performance."**

**A**:

*Situation*: "Our API response times were degrading over 3 months, going from p95 of 300ms to 2 seconds. Customer complaints increased, and we were at risk of missing SLAs."

*Task*: "I was assigned to identify bottlenecks and restore performance to acceptable levels within 2 weeks."

*Action*: "I conducted systematic performance analysis:
1. Added APM (Application Performance Monitoring) instrumentation to trace requests end-to-end
2. Identified database queries as primary bottleneck (80% of request time)
3. Analyzed slow query logs and found missing indexes on frequently-queried columns
4. Worked with DBA to add composite indexes on JOIN and WHERE clause columns
5. Discovered N+1 query pattern in ORM code - worked with dev team to implement eager loading
6. Implemented Redis caching for reference data that rarely changed
7. Tuned database connection pool size based on load testing
8. Set up performance dashboards in Splunk to track improvements"

*Result*: "API response time improved to p95 of 180ms (91% improvement). Database CPU utilization dropped from 85% to 35%, providing headroom for growth. Customer complaints dropped to zero. Implemented automated performance regression testing to catch future issues early."

---

### Example 5: Handling Pressure

**Q: "Describe a high-pressure situation and how you handled it."**

**A**:

*Situation*: "During year-end processing, a critical batch job failed at 3 AM that needed to complete by 6 AM market open for regulatory reporting. The job had run for 5 hours before failing, and logs showed a data corruption issue affecting 10% of records."

*Task*: "I had 3 hours to either fix and rerun, or find a workaround to meet the regulatory deadline."

*Action*: "Under extreme pressure, I:
1. Immediately called an emergency bridge with DBA, dev lead, and my manager
2. Quickly assessed we couldn't fix data corruption and rerun in time (would take 6 hours)
3. Proposed alternative: Process clean 90% of data immediately, manually handle corrupted 10% post-market
4. Got business approval for the approach
5. Modified job to skip corrupted records and log them separately
6. Ran job in 1.5 hours successfully
7. Coordinated with business analysts to manually process problem records throughout the day
8. Stayed online until noon to ensure all data was corrected"

*Result*: "Met regulatory deadline with zero penalties. Completed full data processing by 2 PM. Led RCA that identified root cause (upstream data provider issue). Implemented data validation checks before job processing to catch corruption early. Added monitoring to detect long-running jobs proactively."

---

### Example 6: Mistake/Failure Learning

**Q: "Tell me about a time you made a mistake in production. What did you learn?"**

**A**:

*Situation*: "I was performing what I thought was a routine database index rebuild on a production table. I didn't realize the table was heavily used during business hours, and the rebuild locked the table for 15 minutes, causing application errors."

*Task*: "I needed to restore service and implement processes to prevent similar mistakes."

*Action*: "I immediately:
1. Killed the index rebuild operation to unlock the table
2. Opened an incident ticket and notified affected teams
3. Apologized to stakeholders and took full ownership
4. Conducted a thorough RCA on myself:
   - I hadn't checked table access patterns before the operation
   - I didn't use online index rebuild option
   - I didn't have a maintenance window approval
5. Worked with my manager to implement preventive measures:
   - Created a 'production operations checklist' requiring impact analysis
   - Established maintenance windows for invasive operations
   - Set up table lock monitoring with alerts
   - Implemented peer review for any production database changes
6. Shared the incident and learnings in team meeting to prevent others from making same mistake"

*Result*: "While the mistake impacted users for 15 minutes, the resulting process improvements prevented 5 similar incidents over the next year (caught in peer review). I learned humility and the importance of always considering second-order effects. The checklist became standard practice across the SRE org."

---

### Example 7: Conflict Resolution

**Q: "Tell me about a time you disagreed with a team member or manager."**

**A**:

*Situation*: "My manager wanted to approve a deployment to production on Friday afternoon before a holiday weekend. I believed it was too risky given the limited support coverage if something went wrong."

*Task*: "I needed to advocate for what I believed was right while respecting my manager's decision-making authority."

*Action*: "I:
1. Requested a private conversation to discuss my concerns
2. Presented data: 'Our last 3 Friday deployments had issues, and MTTR was 40% longer on weekends due to reduced staff'
3. Acknowledged the business pressure to release
4. Proposed alternatives:
   - Deploy Tuesday after holiday with full team available
   - Or deploy Friday morning if absolutely needed, with all hands on deck Friday afternoon
   - Keep rollback plan ready and tested
5. Listened to my manager's perspective (customer commitment was made)
6. Agreed to Friday morning deployment with conditions:
   - Extended post-deployment monitoring (4 hours instead of 1)
   - Senior engineers remain available through afternoon
   - Clear rollback criteria established upfront"

*Result*: "Deployment succeeded, but we did identify a minor issue during extended monitoring that we fixed immediately. My manager appreciated that I raised concerns constructively and offered solutions rather than just objecting. This became our new standard for pre-holiday deployments."

---

## Questions to Ask Interviewers

### About the Role

1. **"What does success look like for this role in the first 6 months and first year?"**
   - *Shows*: Goal-oriented, planning ahead

2. **"What are the biggest reliability challenges the WM Product Technology team is currently facing?"**
   - *Shows*: Problem-solving mindset, readiness to contribute

3. **"Can you describe the current on-call rotation structure and how the team handles incident response?"**
   - *Shows*: Understanding of production support realities

4. **"What's the balance between planned work (projects, automation) vs. reactive work (incidents, tickets)?"**
   - *Shows*: TOIL awareness, wanting to drive improvements

5. **"How is the relationship between SRE and Development teams structured? How do you promote collaboration?"**
   - *Shows*: Understanding of cross-functional dynamics

---

### About the Team & Culture

6. **"How does the team approach continuous learning and skill development?"**
   - *Shows*: Growth mindset, commitment to improvement

7. **"What does the blameless post-mortem process look like here?"**
   - *Shows*: Mature SRE thinking, learning culture

8. **"How are SRE initiatives prioritized when there are competing demands from multiple business units?"**
   - *Shows*: Understanding of organizational complexity

9. **"Can you tell me about a recent major initiative the SRE team led? What was the outcome?"**
   - *Shows*: Interest in team accomplishments, learning from examples

10. **"What opportunities exist for SREs to influence architecture and design decisions?"**
    - *Shows*: Wanting to shift-left reliability

---

### About Technology & Tools

11. **"What's the tech stack for the WM platform (languages, frameworks, databases)?"**
    - *Shows*: Technical curiosity, preparation readiness

12. **"How mature is the automation and CI/CD pipeline currently? What are the improvement areas?"**
    - *Shows*: Automation focus, ready to contribute

13. **"What monitoring and observability tools does the team use beyond Splunk and Sockeye?"**
    - *Shows*: Technical depth, tool awareness

14. **"How is infrastructure managed - on-prem, cloud, or hybrid? What's the cloud strategy?"**
    - *Shows*: Modern infrastructure understanding

---

### About Morgan Stanley

15. **"How does Morgan Stanley support work-life balance, especially with the 24/7 on-call requirements?"**
    - *Shows*: Realistic about demands, values sustainability

16. **"What makes the culture of this team unique within Morgan Stanley?"**
    - *Shows*: Cultural fit awareness

17. **"How does Morgan Stanley approach innovation and new technology adoption in the WM space?"**
    - *Shows*: Forward-thinking, innovation interest

18. **"What are the career growth paths from this VP/P5 role?"**
    - *Shows*: Long-term thinking, ambition

---

## Morgan Stanley Culture & Values

### Core Values (Memorize These)

1. **Putting Clients First**
   - *In SRE context*: "System reliability directly impacts client experience. Every deployment decision considers client impact first."

2. **Doing the Right Thing**
   - *In SRE context*: "If I identify a security vulnerability or compliance issue, I escalate immediately even if it delays a project."

3. **Leading with Exceptional Ideas**
   - *In SRE context*: "Bringing innovative automation solutions, proposing SLO-driven development, championing SRE best practices."

4. **Committing to Diversity and Inclusion**
   - *In SRE context*: "Diverse teams bring diverse perspectives that strengthen system design and troubleshooting approaches."

5. **Giving Back**
   - *In SRE context*: "Mentoring junior engineers, contributing to internal knowledge sharing, participating in tech communities."

---

### How to Demonstrate Culture Fit

**During Interview**:
- Use "we" not "I" when discussing team accomplishments (shows collaboration)
- Demonstrate integrity: Mention times you raised concerns or said no to risky requests
- Show humility: Discuss failures and learnings openly
- Exhibit excellence: Use specific metrics and outcomes in examples
- Display teamwork: Emphasize cross-functional collaboration

**Example Response**:
*"What interests you about Morgan Stanley?"*

"I'm drawn to Morgan Stanley for three key reasons:

First, the **scale and criticality** of WM systems align with my passion for high-reliability engineering. Supporting financial advisors and clients where downtime has real financial impact is incredibly motivating.

Second, the **culture of excellence** resonates with my values. I've spent my career in environments where 'good enough' isn't acceptable, and I thrive when held to high standards. Morgan Stanley's 89-year reputation is built on this commitment.

Third, the **collaborative environment between SRE and Dev teams** described in the role is exactly the model I believe in. I've seen firsthand how embedding reliability thinking early in the development lifecycle creates better outcomes than traditional ops-only models.

I'm particularly excited about the opportunity to work in a **VP-level role** where I can drive strategic reliability initiatives, mentor engineers, and influence architecture decisions across the WM platform."

---

## Final Preparation Checklist

### Technical Preparation

- [ ] Review resume and prepare STAR examples for each role/achievement
- [ ] Practice explaining complex technical concepts simply (for non-technical interviewers)
- [ ] Prepare whiteboard scenario: Design a monitoring solution for a trading application
- [ ] Rehearse coding question (if applicable): Script to parse logs and identify error patterns
- [ ] Know your numbers: Latency targets, availability percentages, team sizes, metrics improvements

### Logistics

- [ ] Research interviewers on LinkedIn (understand their backgrounds)
- [ ] Test video conferencing setup (lighting, audio, background)
- [ ] Prepare questions to ask (customize based on interviewer role)
- [ ] Have notepad ready to take notes
- [ ] Charge laptop, have phone backup

### Mindset

- [ ] Get good sleep the night before
- [ ] Arrive 10 minutes early (but not more)
- [ ] Remember: Interview is a two-way evaluation
- [ ] Be authentic - don't oversell or undersell
- [ ] Show enthusiasm and curiosity

### Day-Of Reminders

**Before Each Interview Session**:
- Take 2 minutes to breathe and center yourself
- Review the interviewer's background
- Have your STAR examples mental list ready
- Remember your "why Morgan Stanley" talking points

**During Interview**:
- Listen fully before answering (don't interrupt)
- Ask clarifying questions if needed
- Use specific examples, not generalizations
- Be concise but comprehensive (VP-level communication)
- Show passion for reliability engineering

**After Each Interview Session**:
- Send thank you email within 24 hours
- Reference specific discussion points from your conversation
- Reiterate excitement about the role

---

## Key Talking Points Summary

### Your Elevator Pitch (30 seconds)

"I'm a Senior Site Reliability Engineer with 10+ years of experience building and supporting highly available systems in production environments. I specialize in automating operations, reducing TOIL, and partnering with development teams to build reliability into the software lifecycle. In my recent role, I managed 24/7 production support for a platform processing 10 million daily transactions, where I led automation initiatives that reduced deployment time by 90% and improved system availability from 99.5% to 99.95%. I'm passionate about using data and metrics to drive continuous improvement, and I thrive in high-pressure environments where every minute of downtime matters."

### Why This Role? (1 minute)

"This VP-level SRE role at Morgan Stanley excites me for several reasons:

**The technical challenge**: Supporting WM systems where reliability directly impacts financial advisors and clients requires the highest standards - that's exactly the environment where I do my best work.

**The leadership opportunity**: At the VP level, I can drive strategic reliability initiatives, mentor engineering teams, and influence architecture decisions across the platform, which aligns with where I want to grow my career.

**The collaboration model**: The role's emphasis on working closely with Development, Infrastructure, and Business teams matches my belief that the best reliability outcomes come from cross-functional partnerships.

**The automation focus**: The expectation to continuously reduce TOIL through automation is core to my engineering philosophy. I'm energized by the opportunity to scale operations through intelligent automation.

**Morgan Stanley's culture**: The commitment to excellence, integrity, and doing the right thing aligns with my professional values. I want to work somewhere where quality and client impact matter above all else."

---

## Additional Resources to Review

### Night Before Reading

1. **Morgan Stanley 2024 Annual Report** (Executive Summary)
   - Understand current business priorities
   - WM segment performance and strategy

2. **Recent Morgan Stanley Tech News**
   - Any cloud migration initiatives
   - Technology modernization programs
   - Awards or recognition

3. **SRE Industry Best Practices**
   - Google SRE Book concepts (Error Budgets, Toil, SLOs)
   - Incident Command System
   - Chaos Engineering principles

### Quick Reference Numbers to Know

**Industry Standards**:
- 99.9% availability = 43 min downtime/month
- 99.95% availability = 21.5 min downtime/month
- 99.99% availability = 4.3 min downtime/month
- p95 latency = 95th percentile response time
- TOIL target = < 50% of SRE time

**Your Personal Metrics** (Prepare these from your experience):
- Systems supported (count)
- Users/transactions impacted (volume)
- Availability improvements (%)
- MTTR/MTTD improvements (time)
- Automation ROI (hours saved)
- Team size (people managed/influenced)

---

## Final Words of Encouragement

You have the experience and skills for this role. The key to success tomorrow:

1. **Be confident but humble** - You're an expert, but always learning
2. **Be specific** - Use real examples, numbers, outcomes
3. **Be authentic** - Don't try to be someone you're not
4. **Be curious** - Ask thoughtful questions, show genuine interest
5. **Be professional** - VP-level communication and presence

Remember: Morgan Stanley is evaluating if you can:
- Keep their critical WM systems running reliably
- Lead automation and reliability initiatives
- Partner effectively across teams
- Handle pressure and make good decisions
- Represent the SRE function at a senior level

You've got this. Trust your experience, be yourself, and let your passion for reliability engineering shine through.

**Good luck!**

---

*Document prepared for Senior Site Reliability Engineer, VP, P5 interview at Morgan Stanley*
*Wealth Management Product Technology Team*
*Date: October 2025*