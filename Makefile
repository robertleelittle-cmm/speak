PREFIX ?= $(HOME)/bin

.PHONY: install build clean

build:
	swiftc main.swift -o speak

install: build
	install -d $(PREFIX)
	install speak $(PREFIX)/speak

clean:
	rm -f speak
