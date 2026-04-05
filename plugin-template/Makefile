build:
	groot integration build .

build-into:
	@if [ -z "$(GROOT_HOME)" ]; then echo "Set GROOT_HOME or run: make build-into GROOT_HOME=/path/to/groot-community"; exit 1; fi
	groot integration build . --groot-home "$(GROOT_HOME)"
