default: all

SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(SRC:src/%.ls=lib/%.js)

LS = node_modules/livescript
LSC = node_modules/.bin/lsc
MOCHA = node_modules/.bin/mocha

package.json: package.json.ls
	$(LSC) --compile package.json.ls

lib:
	mkdir lib/

lib/%.js: src/%.ls lib
	$(LSC) --compile --output lib "$<"

.PHONY: build test dev-install loc clean

all: build

build: $(LIB) package.json

test: build
	$(MOCHA) --ui tdd --require livescript "test/**/*.ls"

dev-install: package.json
	npm install .

loc:
	wc -l $(SRC)

clean:
	rm -f package.json
	rm -rf lib
