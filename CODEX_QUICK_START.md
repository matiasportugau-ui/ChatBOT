# Codex Cloud Task - Quick Start

## 🚀 Ready to Run

All scripts and documentation are ready. Follow these steps:

### Step 1: Create Codex Environment (One-time setup)

1. Go to: https://chatgpt.com/codex/settings/environments
2. Click **"Create Environment"**
3. Name: `chatbot-full-training`
4. Connect repository: `matiasportugau-ui/ChatBOT-full`
5. Grant permissions

### Step 2: Start Cloud Task (Phase 1)

**In Codex IDE Extension:**
1. Open Codex panel
2. Select environment: `chatbot-full-training`
3. Toggle **"Run in the cloud"** ON
4. Source: **"Off current branch"** (harden/ci-and-guardrails)
5. In chat, type:

```
Run Phase 1: Training & NLU Testing

Execute: bash scripts/cloud_task_phase1.sh
```

6. Click **"Start Cloud Task"**

### Step 3: Monitor & Download Results

- **In IDE**: Watch progress in Codex panel
- **In Web**: https://chatgpt.com/codex
- **Artifacts**: Automatically collected from `models/` and `reports/`

---

## 📋 What Gets Executed

**Phase 1 Script** (`scripts/cloud_task_phase1.sh`):
- ✅ Python 3.10 virtual environment setup
- ✅ Install dependencies (rasa, pytest, etc.)
- ✅ Validate Rasa data structure
- ✅ Train Rasa model (~5-15 minutes)
- ✅ Run NLU tests on test dataset
- ✅ Run benchmark on full dataset
- ✅ Generate quality report (Macro F1 >= 0.85)

**Output:**
- `models/*.tar.gz` - Trained models
- `reports/*.json` - Test reports
- `reports/*.png` - Visualizations

---

## 📚 Documentation

- **Full Setup Guide**: `CODEX_CLOUD_SETUP.md`
- **Task Commands**: `CODEX_TASK_COMMAND.md`
- **Project README**: `README.md`

---

## ⚙️ Phase 2 (Optional - WhatsApp Testing)

Requires Docker + secrets. See `CODEX_CLOUD_SETUP.md` for Phase 2 setup.

---

## ✅ Verification

After task completes, verify:
- Macro F1 score >= 0.85 (check `reports/intent_report.json`)
- Model file exists in `models/` directory
- Reports generated in `reports/` directory

---

**Ready to start?** Follow Step 2 above! 🎯

