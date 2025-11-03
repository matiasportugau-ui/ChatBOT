# AUTO-ATC Autonomous Agents

This directory contains AI agent configurations for the AUTO-ATC ChatBOT project. These agents run autonomously to maintain documentation, perform quality audits, and monitor system health.

## 🤖 Available Agents

### 1. Documentation Maintainer
**File:** `documentation-maintainer.yml`  
**Schedule:** Every 6 hours  
**Purpose:** Keeps documentation synchronized with code changes

**Tasks:**
- Updates `docs/AVANCE.md` from git history
- Generates `CHECKPOINT.md` with prioritized next actions
- Preserves EXPORT_SEAL metadata blocks
- Auto-commits documentation updates

### 2. Quality Auditor
**File:** `quality-auditor.yml`  
**Schedule:** Daily at 2 AM  
**Purpose:** Analyzes code quality and generates improvement reports

**Tasks:**
- ShellCheck audit on all scripts
- NLU intent balance analysis
- EXPORT_SEAL metadata validation
- Generates actionable fix suggestions

### 3. Service Health Monitor
**File:** `service-health-monitor.yml`  
**Schedule:** Every 30 minutes  
**Purpose:** Monitors Docker services and detects failures

**Tasks:**
- Checks Docker service status
- Identifies unhealthy services
- Generates health reports and alerts
- Provides troubleshooting recommendations

## 🚀 Usage

### Using AI Toolkit in VS Code

1. **Open AI Toolkit**:
   - Click AI Toolkit icon in sidebar
   - Navigate to "Agent Builder"

2. **Import Agent**:
   - Click "Create Agent" or "Import"
   - Select agent YAML file
   - Configure schedule and permissions

3. **Test Agent**:
   ```bash
   # Test locally before deployment
   aitk agent test documentation-maintainer
   ```

4. **Run Agent**:
   ```bash
   # Run manually
   aitk agent run documentation-maintainer
   
   # Run with output
   aitk agent run quality-auditor --output reports/
   ```

### Manual Execution

```bash
# Navigate to project
cd /Users/matias/Projects/ChatBOT

# Activate Python environment
source .venv/bin/activate

# Run documentation update
git log --since="24 hours ago" --oneline
# Then manually update docs/AVANCE.md and CHECKPOINT.md

# Run quality checks
find scripts/ -name "*.sh" -exec shellcheck {} \;
python -c "import yaml; print(yaml.safe_load(open('data/nlu.yml')))"

# Check Docker services
docker compose ps
docker compose logs --tail=50
```

## 📊 Expected Outputs

### Documentation Agent
- `docs/AVANCE.md` - Updated progress tracker
- `CHECKPOINT.md` - Next actions list
- `reports/agent-docs-*.json` - Execution log

### Quality Auditor
- `reports/shellcheck-YYYYMMDD.json` - Script issues
- `reports/shellcheck-summary.md` - Top issues + fixes
- `reports/nlu-balance-YYYYMMDD.json` - Intent distribution
- `reports/export-seal-audit-YYYYMMDD.json` - Metadata validation

### Health Monitor
- `reports/health-latest.json` - Current status
- `reports/health-YYYYMMDD-HHMM.json` - Historical snapshots
- `reports/alerts.json` - Active alerts

## ⚙️ Configuration

### Schedules
- Documentation: `0 */6 * * *` (every 6 hours)
- Quality: `0 2 * * *` (daily at 2 AM)
- Health: `*/30 * * * *` (every 30 minutes)

### Permissions
All agents follow least-privilege principle:
- **Read-only** for source code
- **Write** to `reports/` and `docs/` only
- **Never modify** code without human approval
- **Preserve** EXPORT_SEAL metadata

### Model Configuration
- Model: `gpt-4o`
- Temperature: 0.1-0.3 (deterministic outputs)
- Context window: Full project context

## 🔒 Safety Guardrails

1. **No Direct Code Modifications**: Agents only update documentation and reports
2. **Preserve Metadata**: EXPORT_SEAL blocks are never modified
3. **Audit Trails**: All agent actions logged to `reports/`
4. **Human Approval**: Critical actions require manual intervention
5. **Rollback**: All commits are reversible via git

## 🐛 Troubleshooting

### Agent Not Running
```bash
# Check AI Toolkit status
aitk status

# View agent logs
tail -f reports/agent-*.json

# Restart agent
aitk agent restart documentation-maintainer
```

### Missing Output Files
```bash
# Ensure reports/ directory exists
mkdir -p reports

# Check agent permissions
ls -la agents/*.yml
```

### Commit Conflicts
```bash
# Pull latest changes first
git pull --rebase

# Then run agent
aitk agent run documentation-maintainer
```

## 📝 Development

### Testing New Agents
```bash
# Dry run (shows what would change)
aitk agent run <agent-name> --dry-run

# Validate configuration
aitk agent validate agents/<agent-name>.yml

# Test with limited scope
aitk agent run <agent-name> --files "docs/*.md"
```

### Adding Custom Agents
1. Create new YAML in `agents/`
2. Follow existing agent structure
3. Test locally first
4. Add to README.md
5. Commit and deploy

## 🔗 Related Documentation
- [Project Instructions](../.github/copilot-instructions.md)
- [MCP Tools](../docs/MCP.md)
- [Agent Prompts](../docs/AGENT_PROMPTS.md)

## 📞 Support
For issues or questions:
- Check agent logs in `reports/`
- Review [CHECKPOINT.md](../CHECKPOINT.md) for known issues
- Consult [docs/AVANCE.md](../docs/AVANCE.md) for project status
