PROJECT ?= intrai
TARGETS ?= both

.PHONY: check inventory doctor install-project update-projects

check:
	./check-ai-system.sh

inventory:
	./run-inventory.sh

doctor:
	.venv/bin/python scripts/ai_doctor.py --inventory

install-project:
	.venv/bin/python scripts/install_project_exports.py --project $(PROJECT) --targets $(TARGETS)

update-projects:
	.venv/bin/python scripts/update_project_exports.py --targets $(TARGETS)
