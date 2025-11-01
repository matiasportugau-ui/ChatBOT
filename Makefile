.PHONY: validate train test-nlu

validate:
	python -m rasa data validate

train:
	python -m rasa train

test-nlu:
	mkdir -p reports
	python -m rasa test nlu --nlu tests/test_nlu.yml --out reports
