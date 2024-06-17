.PHONY: test bench docs check

MocPath = $(shell mops toolchain bin moc)

test:
	mops test

check:
	find "./src" -type f -name '*.mo' -print0 | \
	xargs -0 $(MocPath) -r $(shell mops sources) -Werror -wasi-system-api

docs:
	$(shell dfx cache show)/mo-doc
	$(shell dfx cache show)/mo-doc --format plain

bench:
	mops bench  --gc incremental