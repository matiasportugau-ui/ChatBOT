# Codex Cloud Task Setup Guide

This guide walks you through setting up and running the ChatBOT-full project in Codex cloud for training and WhatsApp testing.

## Prerequisites

- Codex account with cloud access
- GitHub repository: `matiasportugau-ui/ChatBOT-full`
- Repository branch: `harden/ci-and-guardrails` (or your preferred branch)

## Step 1: Create Codex Cloud Environment

1. Navigate to [Codex Environments](https://chatgpt.com/codex/settings/environments)
2. Click **"Create Environment"** or select an existing one
3. Configure the environment:
   - **Name**: `chatbot-full-training` (or your preferred name)
   - **Repository**: Connect `matiasportugau-ui/ChatBOT-full`
   - **Permissions**: Grant read/write access to the repository

## Step 2: Configure Environment Variables (Phase 2 Only)

If you plan to run Phase 2 (WhatsApp integration testing), add these secrets to your Codex environment:

### Required for WhatsApp/Chatwoot:
- `CHATWOOT_BASE_URL` - Your Chatwoot instance URL (e.g., `http://localhost:3000` or production URL)
- `CHATWOOT_PLATFORM_TOKEN` - Chatwoot platform API token
- `CHATWOOT_ACCOUNT_ID` - Chatwoot account ID (numeric)
- `CHATWOOT_INBOX_ID` - WhatsApp inbox ID (numeric)
- `BOT_OUTGOING_URL` - n8n webhook URL for bot responses (e.g., `http://localhost:5678/webhook/chatwoot/incoming`)

### Optional (for database setup):
- `N8N_DB_USER` - n8n database user (default: `n8n`)
- `N8N_DB_PASSWORD` - n8n database password (default: `n8n_pass`)
- `CHATWOOT_DB_USER` - Chatwoot database user (default: `chatwoot`)
- `CHATWOOT_DB_PASSWORD` - Chatwoot database password (default: `chatwoot_pass`)

**Note**: For Phase 1 (training + NLU testing), no secrets are required.

## Step 3: Start Cloud Task from IDE

### Option A: Using Codex Extension in VS Code/Cursor

1. Open the Codex panel in your IDE
2. Select your environment: `chatbot-full-training`
3. Enable **"Run in the cloud"** toggle
4. Choose source:
   - **"Off main"** or **"Off current branch"** - Uses clean state from `origin/harden/ci-and-guardrails`
   - **"From local changes"** - Includes your uncommitted changes (not needed for Phase 1)
5. In the chat, provide this task description:

```
Run the cloud task script for Phase 1: Training & NLU Testing

Execute: bash scripts/cloud_task_phase1.sh

This will:
- Set up Python 3.10 virtual environment
- Install dependencies from requirements.txt
- Validate Rasa data structure
- Train the Rasa model
- Run NLU tests on test dataset
- Run benchmark on full NLU dataset
- Generate quality reports

Collect artifacts:
- models/*.tar.gz (trained models)
- reports/*.json (test reports)
- reports/*.png (confusion matrices)
```

6. Click **"Start Cloud Task"**

### Option B: Using Codex Web Interface

1. Go to [Codex Interface](https://chatgpt.com/codex)
2. Select your environment
3. Start a new task with the same description as above

## Step 4: Monitor Progress

### In IDE Extension:
- View task status in the Codex panel
- Check logs in real-time
- See artifact collection progress

### In Web Interface:
- Navigate to your task in the Codex dashboard
- View detailed logs and output
- Download artifacts when complete

## Step 5: Review Results

After the task completes:

1. **Check Quality Gate**:
   - Macro F1 score should be >= 0.85
   - Review `reports/intent_report.json` for detailed metrics

2. **Download Artifacts**:
   - Trained models: `models/*.tar.gz`
   - Test reports: `reports/*.json`
   - Visualizations: `reports/*.png`

3. **Apply Changes Locally** (if any):
   ```bash
   git pull origin <cloud-branch>
   ```

## Phase 2: WhatsApp Integration Testing (Optional)

To run full WhatsApp integration testing:

1. Ensure all environment variables are configured (see Step 2)
2. Start a new cloud task with:

```
Run the cloud task script for Phase 2: WhatsApp Integration Testing

Execute: bash scripts/cloud_task_phase2.sh

This will:
- Start Docker services (PostgreSQL, Redis, Qdrant, Rasa, n8n, Chatwoot)
- Initialize databases
- Create Qdrant collection
- Provision Chatwoot bot
- Verify all services are running

Prerequisites:
- Docker must be available in cloud environment
- All CHATWOOT_* and BOT_OUTGOING_URL environment variables must be set
```

## Troubleshooting

### Python Version Issues
- Cloud environment should have Python 3.10+ available
- Script automatically detects and uses appropriate Python version

### Quality Gate Failures
- If Macro F1 < 0.85, review `reports/intent_report.json`
- Check `data/nlu.yml` for intent balance issues
- Consider adding more training examples

### Docker Issues (Phase 2)
- Ensure Docker is available in cloud environment
- Check service logs: `docker compose logs <service-name>`
- Verify environment variables are correctly set

### Artifact Collection
- Artifacts are automatically collected from `models/` and `reports/` directories
- If artifacts are missing, check script output for errors
- Verify paths in script match actual output locations

## Scripts Reference

- **Phase 1**: `scripts/cloud_task_phase1.sh` - Training & NLU testing (no secrets needed)
- **Phase 2**: `scripts/cloud_task_phase2.sh` - WhatsApp integration (requires secrets + Docker)

## Next Steps

After successful cloud task execution:

1. Review generated models and reports
2. Test trained model locally if needed
3. Integrate results into your workflow
4. Run Phase 2 for end-to-end WhatsApp testing (optional)

For questions or issues, refer to:
- Project README: `README.md`
- CI workflow: `.github/workflows/ci.yml`
- Status document: `docs/STATUS_PROYECTO.md`

