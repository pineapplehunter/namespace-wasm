PREFIX ?= "/usr"

all: sample.wasm

sample.wasm: main.c
	$(CC) $< -o $@

install:
	install -d $(PREFIX)/bin
	install -m 0755 sample.wasm $(PREFIX)/bin/sample.wasm

.PHONY: all install

