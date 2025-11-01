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
