
test:
	$(shell vessel bin)/moc -r $(shell vessel sources) -wasi-system-api ./tests/Test.mo

no-warn:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc -r $(shell vessel sources) -Werror -wasi-system-api
