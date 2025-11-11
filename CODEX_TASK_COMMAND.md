# Codex Cloud Task Command

Copy and paste this into your Codex cloud task:

## Phase 1: Training & NLU Testing (Recommended First)

```bash
bash scripts/cloud_task_phase1.sh
```

**What it does:**
- Sets up Python 3.10 virtual environment
- Installs dependencies from requirements.txt
- Validates Rasa data structure
- Trains the Rasa model
- Runs NLU tests on test dataset (tests/test_nlu.yml)
- Runs benchmark on full NLU dataset (data/nlu.yml)
- Generates quality reports with Macro F1 score

**Artifacts collected:**
- `models/*.tar.gz` - Trained Rasa models
- `reports/*.json` - NLU test reports
- `reports/*.png` - Confusion matrices and histograms

**No secrets required** - This phase runs independently.

---

## Phase 2: WhatsApp Integration Testing (Optional)

```bash
bash scripts/cloud_task_phase2.sh
```

**What it does:**
- Starts Docker services (PostgreSQL, Redis, Qdrant, Rasa, n8n, Chatwoot)
- Initializes databases
- Creates Qdrant collection for products
- Provisions Chatwoot bot
- Verifies all services are running

**Prerequisites:**
- Docker must be available in cloud environment
- Environment variables must be set:
  - `CHATWOOT_BASE_URL`
  - `CHATWOOT_PLATFORM_TOKEN`
  - `CHATWOOT_ACCOUNT_ID`
  - `CHATWOOT_INBOX_ID`
  - `BOT_OUTGOING_URL`

---

## Quick Start

1. Open Codex panel in IDE
2. Select environment: `chatbot-full-training` (create if needed)
3. Enable "Run in the cloud"
4. Choose source: "Off current branch" (harden/ci-and-guardrails)
5. Paste the Phase 1 command above
6. Start task

See `CODEX_CLOUD_SETUP.md` for detailed setup instructions.

