.PHONY: validate train test-nlu benchmark planner setup

validate:
	python -m rasa data validate

train:
	python -m rasa train

test-nlu:
	mkdir -p reports
	python -m rasa test nlu --nlu tests/test_nlu.yml --out reports

benchmark:
	mkdir -p reports
	python -m rasa test nlu --nlu data/nlu.yml --out reports
	python scripts/ci_nlu_summary.py --reports reports

planner:
	python scripts/planner_agent.py

setup:
	chmod +x ./init_project.sh || true
	./init_project.sh

.PHONY: checkpoint
checkpoint:  ## Sync with remote, create session checkpoint, and push
	@echo "🔄 Syncing with remote..."
	@git pull --rebase || echo "⚠️  Pull failed - resolve conflicts manually"
	@echo "📦 Creating session checkpoint..."
	@git add .
	@printf "# AUTO-ATC ChatBOT CHECKPOINT\n\n**Date:** %s\n**Branch:** %s\n**Commit:** %s\n\n---\n\n## 📊 Current Progress\n\n%s\n\n---\n\n## 🎯 Next Actions\n\n%s\n" \
		"$$(date)" \
		"$$(git rev-parse --abbrev-ref HEAD)" \
		"$$(git rev-parse --short HEAD)" \
		"$$(head -30 docs/AVANCE.md 2>/dev/null || echo 'No AVANCE.md found')" \
		"$$(head -20 CHECKPOINT.md 2>/dev/null || echo 'Review project status')" \
		> CHECKPOINT_EXPORT.md
	@git add CHECKPOINT_EXPORT.md
	@git commit -m "checkpoint: session end [$$(date '+%Y-%m-%d %H:%M')]" || echo "⚠️  Nothing to commit"
	@git push || echo "⚠️  Push failed - check remote connection"
	@echo "✅ Checkpoint complete!"
