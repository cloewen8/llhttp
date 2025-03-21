CLANG ?= clang
CFLAGS ?=
OS ?=

CFLAGS += -Os -g3 -Wall -Wextra -Wno-unused-parameter
ifneq ($(OS),Windows_NT) 
	# NOTE: clang on windows does not support fPIC
	CFLAGS += -fPIC
endif

INCLUDES += -Ibuild/

INSTALL ?= install
PREFIX ?= /usr/local
LIBDIR = $(PREFIX)/lib
INCLUDEDIR = $(PREFIX)/include

all: build/libllhttp.a build/libllhttp.so

clean:
	rm -rf release/
	rm -rf build/

build/libllhttp.so: build/c/llhttp.o build/native/api.o \
		build/native/http.o
	$(CLANG) -shared $^ -o $@

build/libllhttp.a: build/c/llhttp.o build/native/api.o \
		build/native/http.o
	$(AR) rcs $@ build/c/llhttp.o build/native/api.o build/native/http.o

build/c/llhttp.o: build/c/llhttp.c
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

build/native/%.o: src/native/%.c build/llhttp.h src/native/api.h \
		build/native
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

build/llhttp.h: generate
build/c/llhttp.c: generate

build/native:
	mkdir -p build/native

release: generate
	mkdir -p release/src
	mkdir -p release/include
	cp -rf build/llhttp.h release/include/
	cp -rf build/c/llhttp.c release/src/
	cp -rf src/native/*.c release/src/
	cp -rf src/llhttp.gyp release/
	cp -rf src/common.gypi release/
	cp -rf CMakeLists.txt release/
	sed -i s/_TAG_/$(TAG)/ release/CMakeLists.txt
	cp -rf libllhttp.pc.in release/
	cp -rf README.md release/
	cp -rf LICENSE-MIT release/

github-release:
	@echo "${RELEASE}" | grep -q -e "^v" || { echo "Please make sure version starts with \"v\"."; exit 1; }
	gh release create -d --generate-notes ${RELEASE}
	@sleep 5
	gh release view ${RELEASE} -t "{{.body}}" --json body > RELEASE_NOTES
	gh release delete ${RELEASE} -y
	gh release create -F RELEASE_NOTES -d --title ${RELEASE} --target release release/${RELEASE}
	@sleep 5
	rm -rf RELEASE_NOTES
	open $$(gh release view release/${RELEASE} --json url -t "{{.url}}")

postversion: release
	git fetch origin
	git push
	git checkout release --
	cp -rf release/* ./
	rm -rf release
	git add include src *.gyp *.gypi CMakeLists.txt README.md LICENSE-MIT libllhttp.pc.in
	git commit -a -m "release: $(TAG)"
	git tag "release/v$(TAG)"
	git push && git push --tags
	git checkout main

generate:
	npx ts-node bin/generate.ts

install: build/libllhttp.a build/libllhttp.so
	$(INSTALL) -d $(DESTDIR)$(INCLUDEDIR)
	$(INSTALL) -d $(DESTDIR)$(LIBDIR)
	$(INSTALL) -C build/llhttp.h $(DESTDIR)$(INCLUDEDIR)/llhttp.h
	$(INSTALL) -C build/libllhttp.a $(DESTDIR)$(LIBDIR)/libllhttp.a
	$(INSTALL) build/libllhttp.so $(DESTDIR)$(LIBDIR)/libllhttp.so

.PHONY: all generate clean release postversion github-release
