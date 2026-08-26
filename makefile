PREFIX        ?= /usr/local
BINDIR        := $(PREFIX)/bin
DESTINATION   := CLIPSQLite
VERSION       ?= 0.1.0

# Private, versioned location for the real binary (never on PATH)
LIBEXECDIR    := $(PREFIX)/libexec/$(DESTINATION)-$(VERSION)

# System-wide share dir for CLIPSQLite data
DATADIR       := $(PREFIX)/share/$(DESTINATION)

CLIPS_VER     := 6.4.2
ARCHIVE       := clips_core_source_642.tar.gz
ARCHIVE_URL   := https://sourceforge.net/projects/clipsrules/files/CLIPS/$(CLIPS_VER)/$(ARCHIVE)
BUILD_DIR     := vendor/clips
TARGET        := $(BUILD_DIR)/clips

WRAPPER       := $(DESTINATION)-$(VERSION)

UNAME_S       := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  CLIPS_OS := DARWIN
else
  CLIPS_OS := LINUX
endif

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

VALGRIND       ?= valgrind
VALGRIND_FLAGS ?= --leak-check=full --errors-for-leak-kinds=none \
                  --num-callers=12 --error-exitcode=1

COVDIR     := $(CURDIR)/coverage
COV_CC     ?= gcc
GCOV       ?= gcov
COV_CFLAGS := -std=c99 -O0 -g --coverage

.PHONY: all clips debug sqlite install install-bin uninstall clean distclean \
        test test-suite test-valgrind coverage help \
        print-sqlite-opts print-sqlite-version FORCE

all: clips

clips: $(TARGET)
	@:

$(TARGET): $(ARCHIVE) userfunctions.c $(SQLITE_DEP) | $(BUILD_DIR)
	cp userfunctions.c $(BUILD_DIR)/
	$(SQLITE_HEADER_STEP)
	$(MAKE) -C $(BUILD_DIR) LDLIBS="$(LDLIBS)"

debug: $(ARCHIVE) $(SQLITE_DEP) | $(BUILD_DIR)
	cp userfunctions.c $(BUILD_DIR)/
	$(SQLITE_HEADER_STEP)
	$(MAKE) -C $(BUILD_DIR) debug LDLIBS="$(LDLIBS)"

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

$(SQLITE_LIB): $(SQLITE_SRC) $(SQLITE_FLAGS)
	$(SQLITE_CC) -c $(SQLITE_CFLAGS) $(SQLITE_OPTS) \
	    -o $(SQLITE_DIR)/sqlite3.o $(SQLITE_SRC)
	$(AR) rcs $@ $(SQLITE_DIR)/sqlite3.o

print-sqlite-opts:
	@echo '$(SQLITE_OPTS)'

print-sqlite-version:
	@echo '$(SQLITE_VERSION)'

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
	[ -f $(ARCHIVE) ] || wget -O $(ARCHIVE) "$(ARCHIVE_URL)"
	tar --strip-components=2 -xvf $(ARCHIVE) -C $(BUILD_DIR)

$(ARCHIVE):
	wget -O $(ARCHIVE) "$(ARCHIVE_URL)"

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

clean:
	-$(MAKE) -C "$(BUILD_DIR)" clean
	-rm -rf "$(COVDIR)" tests/tmp

distclean:
	rm -rf vendor
	rm -f "$(ARCHIVE)"

# ---------------------------------------------------------------------------
# Tests. tests/run.sh runs the in-process suite
# ---------------------------------------------------------------------------

test: all
	./tests/run.sh

test-suite: all
	./tests/run.sh suite

test-valgrind: all
	@command -v $(VALGRIND) >/dev/null 2>&1 || { \
	    echo "$(VALGRIND) not found: install valgrind, or point at it with VALGRIND=/path/to/valgrind" >&2; \
	    exit 1; \
	}
	$(VALGRIND) $(VALGRIND_FLAGS) $(TARGET) -f2 tests/test.bat

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
	    all             'build vendor/clips/clips (the default)' \
	    debug           'the same build with debugging symbols' \
	    sqlite          'fetch, verify and build the pinned SQLite only' \
	    test            'the whole suite: tests/run.sh' \
	    test-suite      'only the in-process suite, tests/test.bat' \
	    test-valgrind   'the in-process suite under valgrind' \
	    coverage        'line coverage of userfunctions.c' \
	    install         'install the binary and its wrapper under PREFIX' \
	    uninstall       'remove what install put there' \
	    clean           'remove objects, coverage and test scratch files' \
	    distclean       'also remove vendor/ and the CLIPS archive'
	@printf '\nSQLite is pinned, downloaded and checked against the SHA3-256\n'
	@printf 'sqlite.org publishes for it. This build uses %s.\n' '$(SQLITE_VERSION)'
	@printf '\n  SQLITE_SYSTEM=1     link the machine`s libsqlite3 instead\n'
	@printf '  SQLITE_DIR=<dir>    build against an amalgamation you supply\n'
	@printf '  SQLITE_VERSION=     pin a different release (also set\n'
	@printf '                      SQLITE_YEAR and SQLITE_SHA3)\n'
	@printf '  SQLITE_OPTS=        compile options for the amalgamation\n'
	@printf '\nOther variables: PREFIX, VERSION, CLIPS (which binary the tests\n'
	@printf 'run), VALGRIND, COV_CC, GCOV.\n'
