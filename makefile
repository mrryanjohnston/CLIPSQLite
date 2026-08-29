PREFIX        ?= /usr/local
BINDIR        := $(PREFIX)/bin
DESTINATION   := CLIPSQLite
VERSION       ?= 0.1.0

# Private, versioned location for the real binary (never on PATH)
LIBEXECDIR    := $(PREFIX)/libexec/$(DESTINATION)-$(VERSION)

# System-wide share dir for CLIPSQLite data
DATADIR       := $(PREFIX)/share/$(DESTINATION)

WRAPPER       := $(DESTINATION)-$(VERSION)

UNAME_S       := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  CLIPS_OS := DARWIN
else
  CLIPS_OS := LINUX
endif

# ---------------------------------------------------------------------------
# Which CLIPS to build against.
#
#   6.4.2    the 6.4.2 release tarball from SourceForge (the default)
#   svn-6x   branches/64x of the CLIPS Subversion repository
#   svn-7x   branches/70x
#
# The two branches are pinned to a revision.
# Override CLIPS_SVN_REV to move one:
#
#   make CLIPS_VERSION=svn-7x
#   make CLIPS_VERSION=svn-7x CLIPS_SVN_REV=978
#   make CLIPS_VERSION=svn-7x CLIPS_SVN_REV=HEAD
#
# Each version is fetched and built under its own directory.
# ---------------------------------------------------------------------------

CLIPS_VERSION  ?= 6.4.2
CLIPS_VERSIONS := 6.4.2 svn-6x svn-7x

ARCHIVE     := clips_core_source_642.tar.gz
ARCHIVE_URL ?= https://sourceforge.net/projects/clipsrules/files/CLIPS/6.4.2/$(ARCHIVE)

CLIPS_SVN_ROOT   ?= https://svn.code.sf.net/p/clipsrules/code
CLIPS_SVN_6X_REV ?= 967
CLIPS_SVN_7X_REV ?= 978

ifeq ($(CLIPS_VERSION),6.4.2)
  CLIPS_TAG    := 6.4.2
  CLIPS_FETCH  := tarball "$(ARCHIVE_URL)" "$(ARCHIVE)"
  CLIPS_ORIGIN := the 6.4.2 release tarball
else ifeq ($(CLIPS_VERSION),svn-6x)
  CLIPS_SVN_URL ?= $(CLIPS_SVN_ROOT)/branches/64x/core
  CLIPS_SVN_REV ?= $(CLIPS_SVN_6X_REV)
  CLIPS_TAG     := svn-6x-r$(CLIPS_SVN_REV)
  CLIPS_FETCH   := svn "$(CLIPS_SVN_URL)" "$(CLIPS_SVN_REV)"
  CLIPS_ORIGIN  := branches/64x at r$(CLIPS_SVN_REV)
else ifeq ($(CLIPS_VERSION),svn-7x)
  CLIPS_SVN_URL ?= $(CLIPS_SVN_ROOT)/branches/70x/core
  CLIPS_SVN_REV ?= $(CLIPS_SVN_7X_REV)
  CLIPS_TAG     := svn-7x-r$(CLIPS_SVN_REV)
  CLIPS_FETCH   := svn "$(CLIPS_SVN_URL)" "$(CLIPS_SVN_REV)"
  CLIPS_ORIGIN  := branches/70x at r$(CLIPS_SVN_REV)
else
  $(error CLIPS_VERSION is '$(CLIPS_VERSION)': expected one of $(CLIPS_VERSIONS))
endif

CLIPS_SRC_DIR := vendor/clips-source/$(CLIPS_TAG)
BUILD_DIR     := vendor/clips-build/$(CLIPS_TAG)
TARGET        := $(BUILD_DIR)/clips

CLIPS_SRC_STAMP := $(CLIPS_SRC_DIR)/.clips-source
BUILD_STAMP     := $(BUILD_DIR)/.clips-source

CLIPS_LINK := vendor/clips

CLIPS   ?=
CLIPS_BIN = $(if $(strip $(CLIPS)),$(CLIPS),$(TARGET))

SQLITE_VERSION ?= 3.53.4
SQLITE_YEAR    ?= 2026
SQLITE_SHA3    ?= 628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e

# sqlite.org names its files with the version flattened: 3.53.4 -> 3530400
sqlite_v  := $(subst ., ,$(SQLITE_VERSION))
SQLITE_ID := $(shell printf '%d%02d%02d00' $(word 1,$(sqlite_v)) $(word 2,$(sqlite_v)) $(word 3,$(sqlite_v)))

SQLITE_DIR ?= $(CURDIR)/vendor/sqlite-$(SQLITE_VERSION)

SQLITE_ZIP := sqlite-amalgamation-$(SQLITE_ID).zip
SQLITE_URL ?= https://sqlite.org/$(SQLITE_YEAR)/$(SQLITE_ZIP)
SQLITE_SRC := $(SQLITE_DIR)/sqlite3.c
SQLITE_HDR := $(SQLITE_DIR)/sqlite3.h
SQLITE_LIB := $(SQLITE_DIR)/libsqlite3.a
SQLITE_FLAGS := $(SQLITE_DIR)/.build-flags

SQLITE_OPTS ?= -DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_THREADSAFE=1
SQLITE_CC     ?= $(CC)
SQLITE_CFLAGS ?= -O2 -fPIC

ifeq ($(UNAME_S),Darwin)
  SQLITE_SYSLIBS :=
else
  SQLITE_SYSLIBS := -lpthread -ldl
endif

# ---------------------------------------------------------------------------
# SQLITE_SYSTEM=1 goes back to linking whatever libsqlite3 the machine has,
# for a packager who would rather ship against the system library than a copy
# of it.
# ---------------------------------------------------------------------------
ifeq ($(SQLITE_SYSTEM),1)
  LDLIBS     := -lm -lsqlite3
  SQLITE_DEP :=
  SQLITE_HEADER_STEP := rm -f $(BUILD_DIR)/sqlite3.h
else
  LDLIBS     := -lm $(SQLITE_LIB) $(SQLITE_SYSLIBS)
  SQLITE_DEP := $(SQLITE_LIB)
  SQLITE_HEADER_STEP := cp $(SQLITE_HDR) $(BUILD_DIR)/sqlite3.h
endif

# Which SQLite the binary links against is not visible in any prerequisite:
# both choices build the same $(TARGET) out of the same sources, so toggling
# SQLITE_SYSTEM in a tree that is already built used to leave the old binary
# sitting there. Recording the link in a stamp beside the build gives make
# something it can notice, the same way $(SQLITE_FLAGS) does for the options
# the amalgamation was compiled with.
LINK_STAMP := $(BUILD_DIR)/.link-flags

VALGRIND       ?= valgrind
VALGRIND_FLAGS ?= --leak-check=full --errors-for-leak-kinds=none \
                  --num-callers=12 --error-exitcode=1

COVDIR     := $(CURDIR)/coverage
COV_CC     ?= gcc
GCOV       ?= gcov
COV_CFLAGS := -std=c99 -O0 -g --coverage

.PHONY: all clips clips-source debug sqlite install install-bin uninstall clean distclean \
        test test-all test-suite test-examples test-valgrind coverage help \
        print-sqlite-opts print-sqlite-version print-clips print-clips-target \
        print-clips-versions FORCE

all: clips

clips: $(TARGET)
	@:

# ---------------------------------------------------------------------------
# Fetching and building CLIPS.
#
# scripts/fetch-clips.sh puts a pristine tree in $(CLIPS_SRC_DIR); the build
# happens in a copy of it, because userfunctions.c and sqlite3.h have to be
# dropped in beside the CLIPS sources for the CLIPS makefile to find them.
# ---------------------------------------------------------------------------

$(CLIPS_SRC_STAMP): | scripts/fetch-clips.sh
	./scripts/fetch-clips.sh $(CLIPS_FETCH) "$(CLIPS_SRC_DIR)"

$(BUILD_STAMP): $(CLIPS_SRC_STAMP)
	mkdir -p "$(BUILD_DIR)"
	cp -R "$(CLIPS_SRC_DIR)/." "$(BUILD_DIR)/"
	touch "$@"

# vendor/clips is a symlink to the version built last.
define point_clips_link
	@[ ! -e "$(CLIPS_LINK)" ] || [ -L "$(CLIPS_LINK)" ] || rm -rf "$(CLIPS_LINK)"
	@ln -sfn "clips-build/$(CLIPS_TAG)" "$(CLIPS_LINK)"
	@echo "$(CLIPS_LINK) -> clips-build/$(CLIPS_TAG)  ($(CLIPS_ORIGIN))"
endef

$(TARGET): userfunctions.c $(SQLITE_DEP) $(BUILD_STAMP) $(LINK_STAMP)
	cp userfunctions.c $(BUILD_DIR)/
	$(SQLITE_HEADER_STEP)
	$(MAKE) -C $(BUILD_DIR) LDLIBS="$(LDLIBS)"
	$(point_clips_link)

debug: userfunctions.c $(SQLITE_DEP) $(BUILD_STAMP) $(LINK_STAMP)
	cp userfunctions.c $(BUILD_DIR)/
	$(SQLITE_HEADER_STEP)
	$(MAKE) -C $(BUILD_DIR) debug LDLIBS="$(LDLIBS)"
	$(point_clips_link)

# Fetching the selected CLIPS without building it, for priming a cache or
# for looking at what a branch is doing.
clips-source: $(CLIPS_SRC_STAMP)
	@cat "$(CLIPS_SRC_STAMP)"

sqlite: $(SQLITE_LIB)

$(SQLITE_SRC): | scripts/fetch-sqlite.sh
	./scripts/fetch-sqlite.sh "$(SQLITE_URL)" "$(SQLITE_SHA3)" "$(SQLITE_DIR)"

$(SQLITE_HDR): $(SQLITE_SRC)
	@:

$(SQLITE_FLAGS): FORCE
	@mkdir -p $(@D)
	@printf '%s\n' '$(SQLITE_CC) $(SQLITE_CFLAGS) $(SQLITE_OPTS)' | cmp -s - $@ 2>/dev/null || \
	    printf '%s\n' '$(SQLITE_CC) $(SQLITE_CFLAGS) $(SQLITE_OPTS)' > $@

FORCE:

$(LINK_STAMP): FORCE
	@mkdir -p $(@D)
	@printf '%s\n' '$(LDLIBS)' | cmp -s - $@ 2>/dev/null || \
	    printf '%s\n' '$(LDLIBS)' > $@

$(SQLITE_LIB): $(SQLITE_SRC) $(SQLITE_FLAGS)
	$(SQLITE_CC) -c $(SQLITE_CFLAGS) $(SQLITE_OPTS) \
	    -o $(SQLITE_DIR)/sqlite3.o $(SQLITE_SRC)
	$(AR) rcs $@ $(SQLITE_DIR)/sqlite3.o

print-sqlite-opts:
	@echo '$(SQLITE_OPTS)'

print-sqlite-version:
	@echo '$(SQLITE_VERSION)'

print-clips-versions:
	@echo '$(CLIPS_VERSIONS)'

print-clips-target:
	@echo '$(TARGET)'

print-clips:
	@echo 'CLIPS_VERSION $(CLIPS_VERSION)'
	@echo 'origin        $(CLIPS_ORIGIN)'
	@echo 'source        $(CLIPS_SRC_DIR)'
	@echo 'build         $(BUILD_DIR)'
	@echo 'binary        $(TARGET)'
	@[ -f "$(CLIPS_SRC_STAMP)" ] && printf 'fetched       ' && cat "$(CLIPS_SRC_STAMP)" || true

install: clips install-bin

install-bin:
	install -d "$(LIBEXECDIR)" "$(BINDIR)"
	install -m755 "$(TARGET)" "$(LIBEXECDIR)/clips"
	sed -e 's|@REAL@|$(LIBEXECDIR)/clips|g' \
	    -e 's|@VERSION@|$(VERSION)|g' \
	    CLIPSQLite.in > "$(BINDIR)/$(WRAPPER)"
	chmod 755 "$(BINDIR)/$(WRAPPER)"
	ln -sfn "$(WRAPPER)" "$(BINDIR)/$(DESTINATION)"

uninstall:
	rm -f "$(BINDIR)/$(WRAPPER)" "$(BINDIR)/$(DESTINATION)"
	rm -rf "$(LIBEXECDIR)"
	rmdir "$(DATADIR)" 2>/dev/null || true

# The fetched sources under vendor/clips-source are left alone: they are the
# slow half to get back, and nothing a build writes goes there.
clean:
	-rm -rf vendor/clips-build "$(CLIPS_LINK)"
	-rm -rf "$(COVDIR)" tests/tmp examples/tmp

distclean:
	rm -rf vendor
	rm -f "$(ARCHIVE)"

# ---------------------------------------------------------------------------
# Tests.  tests/run.sh runs the in-process suite and then the examples, each
# checked against the .expected file beside it, so an example that stops
# working fails the build rather than sitting in the repository misleading
# someone.
#
# Every target here runs against one CLIPS.  test-all runs the whole thing
# against all three in turn, which is what CI does across three runners.
# ---------------------------------------------------------------------------

test: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh

test-suite: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh suite

test-examples: all
	CLIPS="$(CLIPS_BIN)" ./tests/run.sh examples

# CLIPS= empties whatever was inherited: each version has to be tested
# against its own binary for this to mean anything.
test-all:
	@for v in $(CLIPS_VERSIONS); do \
	    echo; \
	    echo "=== CLIPS_VERSION=$$v ==="; \
	    $(MAKE) --no-print-directory CLIPS= CLIPS_VERSION="$$v" test || exit 1; \
	done

test-valgrind: all
	@command -v $(VALGRIND) >/dev/null 2>&1 || { \
	    echo "$(VALGRIND) not found: install valgrind, or point at it with VALGRIND=/path/to/valgrind" >&2; \
	    exit 1; \
	}
	$(VALGRIND) $(VALGRIND_FLAGS) $(CLIPS_BIN) -f2 tests/test.bat

# ---------------------------------------------------------------------------
# Line coverage of the wrappers, and the list of the ones no test entered.
# ---------------------------------------------------------------------------
coverage: clips
	mkdir -p "$(COVDIR)"
	cp userfunctions.c "$(COVDIR)/"
	$(COV_CC) -c -D$(CLIPS_OS) $(COV_CFLAGS) -I"$(BUILD_DIR)" \
	    -o "$(COVDIR)/userfunctions.o" "$(COVDIR)/userfunctions.c"
	cp "$(BUILD_DIR)/libclips.a" "$(COVDIR)/libclips.a"
	ar d "$(COVDIR)/libclips.a" userfunctions.o
	ar r "$(COVDIR)/libclips.a" "$(COVDIR)/userfunctions.o"
	$(COV_CC) -o "$(COVDIR)/clips" "$(BUILD_DIR)/main.o" \
	    -L"$(COVDIR)" -lclips --coverage $(LDLIBS)
	rm -f "$(COVDIR)/userfunctions.gcda"
	: > "$(COVDIR)/never-entered.txt"
	CLIPS="$(COVDIR)/clips" ./tests/run.sh || true
	cd "$(COVDIR)" && $(GCOV) -b -f userfunctions.c > by-function.txt
	@echo
	@sed -n "/^File .*userfunctions\.c/,/^Creating/p" "$(COVDIR)/by-function.txt" | grep -v '^Creating'
	@grep -v '^[[:space:]]*//' userfunctions.c | grep 'AddUDF(' \
	    | grep -oE '"Sqlite[A-Za-z0-9_]*Function"' | tr -d '"' | sort -u \
	    > "$(COVDIR)/registered-udfs.txt"
	@awk -v out="$(COVDIR)/never-entered.txt" \
	     'NR==FNR { udf[$$0]=1; next } \
	      /^Function / { fn=substr($$2,2,length($$2)-2); want=(fn in udf); next } \
	      /^Lines executed:/ && want { \
	        want=0; p=$$2; sub(/^executed:/,"",p); sub(/%$$/,"",p); \
	        n=$$4+0; fns++; tot+=n; cov+=p*n/100; \
	        if (p+0==0) { zero++; print fn > out } } \
	      END { if (tot) printf "\nUDF handlers only: %d registered, %d lines, %.1f%% executed (%d never entered)\n", fns, tot, 100*cov/tot, zero }' \
	    "$(COVDIR)/registered-udfs.txt" "$(COVDIR)/by-function.txt"
	@echo
	@echo "per-function detail: $(COVDIR)/by-function.txt"
	@echo "annotated source:    $(COVDIR)/userfunctions.c.gcov"
	@echo "never entered:       $(COVDIR)/never-entered.txt"

help:
	@printf 'CLIPSQLite targets:\n\n'
	@printf '  %-16s %s\n' \
	    all             'build the binary against one CLIPS (the default)' \
	    debug           'the same build with debugging symbols' \
	    sqlite          'fetch, verify and build the pinned SQLite only' \
	    clips-source    'fetch the selected CLIPS without building it' \
	    test            'the whole suite and the examples: tests/run.sh' \
	    test-all        'build and test against all three CLIPS versions' \
	    test-suite      'only the in-process suite, tests/test.bat' \
	    test-examples   'only the examples, checked against examples/*.expected' \
	    test-valgrind   'the in-process suite under valgrind' \
	    coverage        'line coverage of userfunctions.c' \
	    install         'install the binary and its wrapper under PREFIX' \
	    uninstall       'remove what install put there' \
	    clean           'remove the build trees, coverage and test scratch' \
	    distclean       'also remove the fetched CLIPS and SQLite sources'
	@printf '\nCLIPS is built from one of three sources, selected with\n'
	@printf 'CLIPS_VERSION. This build uses %s: %s.\n' \
	    '$(CLIPS_VERSION)' '$(CLIPS_ORIGIN)'
	@printf '\n  CLIPS_VERSION=6.4.2   the release tarball from SourceForge\n'
	@printf '  CLIPS_VERSION=svn-6x  branches/64x, pinned at r%s\n' '$(CLIPS_SVN_6X_REV)'
	@printf '  CLIPS_VERSION=svn-7x  branches/70x, pinned at r%s\n' '$(CLIPS_SVN_7X_REV)'
	@printf '  CLIPS_SVN_REV=        build a branch at another revision,\n'
	@printf '                        or at HEAD (needs svn installed)\n'
	@printf '  CLIPS_SVN_URL=        take the branch from somewhere else\n'
	@printf '\nEach version is fetched and built under its own directory, and\n'
	@printf 'vendor/clips points at the one built last. "make print-clips"\n'
	@printf 'says which that is.\n'
	@printf '\nSQLite is pinned, downloaded and checked against the SHA3-256\n'
	@printf 'sqlite.org publishes for it. This build uses %s.\n' '$(SQLITE_VERSION)'
	@printf '\n  SQLITE_SYSTEM=1     link the machine`s libsqlite3 instead\n'
	@printf '  SQLITE_DIR=<dir>    build against an amalgamation you supply\n'
	@printf '  SQLITE_VERSION=     pin a different release (also set\n'
	@printf '                      SQLITE_YEAR and SQLITE_SHA3)\n'
	@printf '  SQLITE_OPTS=        compile options for the amalgamation\n'
	@printf '\nOther variables: PREFIX, VERSION, CLIPS (which binary the tests\n'
	@printf 'run), VALGRIND, COV_CC, GCOV.\n'
