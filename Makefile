PROJECT ?= intrai
TARGETS ?= both

.PHONY: check inventory doctor install-project update-projects \
	gui-check gui-inventory gui-doctor \
	gui-update gui-update-codex gui-update-claude gui-install-project \
	gui-open-inventory gui-open-doctor \
	gui-open-readme gui-open-operations gui-open-skill-workflow gui-open-project-onboarding gui-open-plan gui-open-local-gui-design \
	gui-install-hooks gui-git-status \
	gui-open-cursor gui-open-terminal gui-open-finder \
	build-gui-app build-swift-app add-project

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

# GUI Layer Targets — backed by scripts/ai_system_action.sh

gui-check:
	@scripts/ai_system_action.sh check

gui-inventory:
	@scripts/ai_system_action.sh inventory

gui-doctor:
	@scripts/ai_system_action.sh doctor

gui-update:
	@scripts/ai_system_action.sh update

gui-update-codex:
	@scripts/ai_system_action.sh update-codex

gui-update-claude:
	@scripts/ai_system_action.sh update-claude

gui-install-project:
	@scripts/ai_system_action.sh install-project $(PROJECT) $(TARGETS)

gui-open-inventory:
	@scripts/ai_system_action.sh open-inventory

gui-open-doctor:
	@scripts/ai_system_action.sh open-doctor

gui-open-readme:
	@scripts/ai_system_action.sh open-readme

gui-open-operations:
	@scripts/ai_system_action.sh open-operations

gui-open-skill-workflow:
	@scripts/ai_system_action.sh open-skill-workflow

gui-open-project-onboarding:
	@scripts/ai_system_action.sh open-project-onboarding

gui-open-plan:
	@scripts/ai_system_action.sh open-plan

gui-open-local-gui-design:
	@scripts/ai_system_action.sh open-local-gui-design

gui-install-hooks:
	@scripts/ai_system_action.sh install-hooks

gui-git-status:
	@scripts/ai_system_action.sh git-status

gui-open-cursor:
	@scripts/ai_system_action.sh open-cursor

gui-open-terminal:
	@scripts/ai_system_action.sh open-terminal

gui-open-finder:
	@scripts/ai_system_action.sh open-finder

build-gui-app:
	@bash scripts/build_ai_system_app.sh

build-swift-app:
	@bash scripts/build_swift_app.sh

add-project:
	@scripts/ai_system_action.sh add-project $(PROJECT) $(PROJECT_PATH) $(TARGETS) $(INSTALL_NOW)
