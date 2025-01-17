.DEFAULT_GOAL := help

# Colors
CYAN = \033[36m
YELLOW = \033[33m
GREEN = \033[32m
RESET = \033[0m

test: ## 🧪 Run test suite in Docker container
	@echo "${GREEN}🧪 Running tests${RESET}"
	@docker run -it --rm local/plantuml:latest sh ./scripts/run_tests.sh

lint: ## 🔍 Run luacheck on Lua files
	@echo "${YELLOW}🔍 Running luacheck${RESET}"
	luacheck lua/* tests/*

docgen: ## 📚 Generate documentation
	@echo "${CYAN}📚 Generating documentation${RESET}"
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "luafile ./scripts/gendocs.lua" -c 'qa'

build: ## 🏗️  Build Docker image
	@echo "${GREEN}🏗️  Building Docker image${RESET}"
	@docker buildx build --load -t local/plantuml .

help: ## 💡 Show available commands
	@echo "${CYAN}💡 Neovim PlantUML makefile${RESET}"
	@echo "${CYAN}═══════════════════════════${RESET}\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) 2>/dev/null \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; \
		{printf "  ${CYAN}%-15s${RESET} %s\n", $$1, $$2}'

.PHONY: test lint docgen build help
