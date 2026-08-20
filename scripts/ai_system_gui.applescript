-- AI System Local GUI - French UX with Unicode symbols
-- Backend: scripts/ai_system_action.sh with AI_SYSTEM_UI_MODE=app

property aiSystemRoot : "/Users/vincentdesbrosses/Documents/Misc/ai-system"
property UI_MODE : "app"

-- === Safe dialog handlers ===

on safeChooseFromList(listItems, windowTitle, prompt)
	try
		set choice to choose from list listItems with title windowTitle with prompt prompt
		if choice is false then
			return "__CANCELLED__"
		end if
		return item 1 of choice
	on error errMsg number errNum
		if errNum = -128 then
			return "__CANCELLED__"
		else
			error "Dialog error: " & errMsg
		end if
	end try
end safeChooseFromList

on safeChooseWithDefault(listItems, windowTitle, prompt, defaultItem)
	try
		set choice to choose from list listItems with title windowTitle with prompt prompt default items {defaultItem}
		if choice is false then
			return "__CANCELLED__"
		end if
		return item 1 of choice
	on error errMsg number errNum
		if errNum = -128 then
			return "__CANCELLED__"
		else
			error "Dialog error: " & errMsg
		end if
	end try
end safeChooseWithDefault

on safeDisplayDialog(prompt, title, defaultAnswer)
	try
		set response to display dialog prompt default answer defaultAnswer with title title
		if response = false then
			return "__CANCELLED__"
		end if
		return text returned of response
	on error errMsg number errNum
		if errNum = -128 then
			return "__CANCELLED__"
		else
			error "Dialog error: " & errMsg
		end if
	end try
end safeDisplayDialog

-- === Action runners ===

on runAction(actionName)
	set cmd to "AI_SYSTEM_UI_MODE=" & UI_MODE & " " & aiSystemRoot & "/scripts/ai_system_action.sh " & actionName
	try
		do shell script cmd
		return {success:true, message:"Action executed."}
	on error errMsg
		return {success:false, message:"Error: " & errMsg}
	end try
end runAction

on runInstallProject(projName, tgtName)
	set cmd to "AI_SYSTEM_UI_MODE=" & UI_MODE & " " & aiSystemRoot & "/scripts/ai_system_action.sh install-project " & projName & " " & tgtName
	try
		do shell script cmd
		return {success:true, message:"Project " & projName & " (" & tgtName & ") installed."}
	on error errMsg
		return {success:false, message:"Install error: " & errMsg}
	end try
end runInstallProject

on runAddProject(projName, projPath, targets, installNow)
	set cmd to "AI_SYSTEM_UI_MODE=" & UI_MODE & " " & aiSystemRoot & "/scripts/ai_system_action.sh add-project " & projName & " " & projPath & " " & targets & " " & installNow
	try
		do shell script cmd
		return {success:true, message:"Project " & projName & " added."}
	on error errMsg
		return {success:false, message:"Add error: " & errMsg}
	end try
end runAddProject

on showResult(result)
	if result's success then
		display notification (result's message) with title "AI System"
	else
		set theButton to button returned of (display alert "Attention" message (result's message) buttons {"OK", "View Log"} default button 1)
		if theButton = "View Log" then
			do shell script "open " & aiSystemRoot & "/logs/ai-system-last-action.log"
		end if
	end if
end showResult

-- === Menus ===

on mainMenu()
	set mainOptions to {"✓ Verifier que tout est OK", "↻ Diffuser les mises a jour partout", "▣ Mettre a jour un projet", "◉ Ajouter un nouveau projet", "◇ Voir les rapports", "⚙ Ouvrir la documentation", "► Outils locaux", "❌ Quitter"}
	set choice to safeChooseFromList(mainOptions, "AI System", "Que veux-tu faire?")

	if choice = "__CANCELLED__" then return

	if choice starts with "✓" then
		set result to runAction("check")
		showResult(result)
		delay 0.5
		mainMenu()

	else if choice starts with "↻" then
		exportsMenu()
		mainMenu()

	else if choice starts with "▣" then
		projectMenu()
		mainMenu()

	else if choice starts with "◉" then
		addProjectMenu()
		mainMenu()

	else if choice starts with "◇" then
		reportsMenu()
		mainMenu()

	else if choice starts with "⚙" then
		docsMenu()
		mainMenu()

	else if choice starts with "►" then
		toolsMenu()
		mainMenu()

	else if choice starts with "❌" then
		return
	end if
end mainMenu

on exportsMenu()
	set opts to {"↻ Tout diffuser (Claude + Codex)", "◇ Codex seulement", "◇ Claude seulement", "← Retour"}
	set choice to safeChooseFromList(opts, "Diffusion", "Choisir:")

	if choice = "__CANCELLED__" or choice starts with "←" then return

	if choice starts with "↻" then
		set result to runAction("update")
		showResult(result)

	else if choice starts with "◇ Codex" then
		set result to runAction("update-codex")
		showResult(result)

	else if choice starts with "◇ Claude" then
		set result to runAction("update-claude")
		showResult(result)
	end if
end exportsMenu

on projectMenu()
	set projName to safeDisplayDialog("Nom du projet a mettre a jour:", "Mise a jour", "")
	if projName = "__CANCELLED__" or projName = "" then return

	set targets to {"▣ Codex seulement", "▣ Claude seulement", "▣ Claude + Codex"}
	set targName to safeChooseWithDefault(targets, "Cible", "Choisir:", "▣ Claude + Codex")
	if targName = "__CANCELLED__" then return

	set targetMap to {{"▣ Codex seulement", "codex"}, {"▣ Claude seulement", "claude"}, {"▣ Claude + Codex", "both"}}
	set mappedTarget to ""
	repeat with mapping in targetMap
		if mapping's item 1 = targName then
			set mappedTarget to mapping's item 2
			exit repeat
		end if
	end repeat

	set result to runInstallProject(projName, mappedTarget)
	showResult(result)
end projectMenu

on addProjectMenu()
	set projName to safeDisplayDialog("Nom du nouveau projet:", "Ajouter", "")
	if projName = "__CANCELLED__" or projName = "" then return

	set projPath to safeDisplayDialog("Chemin absolu du projet:", "Ajouter", "")
	if projPath = "__CANCELLED__" or projPath = "" then return

	set targets to {"▣ Codex seulement", "▣ Claude seulement", "▣ Claude + Codex"}
	set targName to safeChooseWithDefault(targets, "Cible", "Choisir:", "▣ Claude + Codex")
	if targName = "__CANCELLED__" then return

	set targetMap to {{"▣ Codex seulement", "codex"}, {"▣ Claude seulement", "claude"}, {"▣ Claude + Codex", "both"}}
	set mappedTarget to ""
	repeat with mapping in targetMap
		if mapping's item 1 = targName then
			set mappedTarget to mapping's item 2
			exit repeat
		end if
	end repeat

	set installOpts to {"✓ Installer les commands/skills maintenant", "◇ Ajouter seulement au registre"}
	set installChoice to safeChooseWithDefault(installOpts, "Installation", "Choisir:", "✓ Installer les commands/skills maintenant")
	if installChoice = "__CANCELLED__" then return

	set installNow to "false"
	if installChoice starts with "✓" then
		set installNow to "true"
	end if

	set result to runAddProject(projName, projPath, mappedTarget, installNow)
	showResult(result)
end addProjectMenu

on reportsMenu()
	set opts to {"◇ Rapport Inventory", "◇ Rapport Doctor", "← Retour"}
	set choice to safeChooseFromList(opts, "Rapports", "Choisir:")

	if choice = "__CANCELLED__" or choice starts with "←" then return

	if choice starts with "◇ Inventory" then
		do shell script "open " & aiSystemRoot & "/reports/ai-inventory.latest.md"
		display notification "Rapport ouvert" with title "AI System"

	else if choice starts with "◇ Doctor" then
		do shell script "open " & aiSystemRoot & "/reports/ai-doctor.latest.md"
		display notification "Rapport ouvert" with title "AI System"
	end if
end reportsMenu

on docsMenu()
	set opts to {"✓ README", "⚙ Guide d'exploitation", "⚙ Workflow des skills", "⚙ Onboarding projet", "⚙ Design interface", "⚙ Plan AI System", "← Retour"}
	set choice to safeChooseFromList(opts, "Documentation", "Choisir:")

	if choice = "__CANCELLED__" or choice starts with "←" then return

	if choice starts with "✓" then
		do shell script "open " & aiSystemRoot & "/README.md"
	else if choice starts with "⚙ Guide" then
		do shell script "open " & aiSystemRoot & "/docs/OPERATIONS.md"
	else if choice starts with "⚙ Workflow" then
		do shell script "open " & aiSystemRoot & "/docs/SKILL-WORKFLOW.md"
	else if choice starts with "⚙ Onboarding" then
		do shell script "open " & aiSystemRoot & "/docs/PROJECT-ONBOARDING.md"
	else if choice starts with "⚙ Design" then
		do shell script "open " & aiSystemRoot & "/docs/LOCAL-GUI-DESIGN.md"
	else if choice starts with "⚙ Plan" then
		do shell script "open " & aiSystemRoot & "/Plan-AI-System.md"
	end if

	display notification "Document ouvert" with title "AI System"
end docsMenu

on toolsMenu()
	set opts to {"✓ Lancer Inventory", "✓ Lancer Doctor", "⚙ Installer hook", "▣ Voir l'etat Git", "◇ Ouvrir log", "→ Cursor", "→ Terminal", "→ Finder", "◉ Recreer app", "← Retour"}
	set choice to safeChooseFromList(opts, "Outils", "Choisir:")

	if choice = "__CANCELLED__" or choice starts with "←" then return

	if choice starts with "✓ Inventory" then
		set result to runAction("inventory")
		showResult(result)

	else if choice starts with "✓ Doctor" then
		set result to runAction("doctor")
		showResult(result)

	else if choice starts with "⚙ Installer" then
		set result to runAction("install-hooks")
		showResult(result)

	else if choice starts with "▣" then
		set result to runAction("git-status")
		showResult(result)

	else if choice starts with "◇" then
		do shell script "open " & aiSystemRoot & "/logs/ai-system-last-action.log"
		display notification "Log ouvert" with title "AI System"

	else if choice starts with "→ Cursor" then
		do shell script "cursor " & aiSystemRoot
		display notification "Cursor ouvert" with title "AI System"

	else if choice starts with "→ Terminal" then
		do shell script "open -a Terminal " & aiSystemRoot
		display notification "Terminal ouvert" with title "AI System"

	else if choice starts with "→ Finder" then
		do shell script "open " & aiSystemRoot
		display notification "Finder ouvert" with title "AI System"

	else if choice starts with "◉" then
		set result to runAction("build-gui-app")
		showResult(result)
	end if
end toolsMenu

mainMenu()
