.PHONY: check inventory doctor

check:
	./check-ai-system.sh

inventory:
	./run-inventory.sh

doctor:
	.venv/bin/python scripts/ai_doctor.py --inventory
