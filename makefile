PREFIX        ?= /usr/local
BINDIR        := $(PREFIX)/bin
DESTINATION   := CLIPSQLite
VERSION       ?= 0.1.0

# Private, versioned location for the real binary (never on PATH)
LIBEXECDIR    := $(PREFIX)/libexec/$(DESTINATION)-$(VERSION)

# System-wide share dir for CLIPSQLite data
DATADIR       := $(PREFIX)/share/$(DESTINATION)
DATAFILES     := deftemplates.clp defclasses.clp

CLIPS_VER     := 6.4.2
ARCHIVE       := clips_core_source_642.tar.gz
ARCHIVE_URL   := https://sourceforge.net/projects/clipsrules/files/CLIPS/$(CLIPS_VER)/$(ARCHIVE)
BUILD_DIR     := vendor/clips
TARGET        := $(BUILD_DIR)/clips
LDLIBS        := -lm -lsqlite3

WRAPPER       := $(DESTINATION)-$(VERSION)

.PHONY: all clips debug install install-bin uninstall clean distclean

all: clips

clips: $(TARGET)
	@:

$(TARGET): $(ARCHIVE) userfunctions.c | $(BUILD_DIR)
	cp userfunctions.c $(BUILD_DIR)/
	$(MAKE) -C $(BUILD_DIR) LDLIBS="$(LDLIBS)"

debug: $(ARCHIVE) | $(BUILD_DIR)
	cp userfunctions.c $(BUILD_DIR)/
	$(MAKE) -C $(BUILD_DIR) debug LDLIBS="$(LDLIBS)"

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

distclean:
	rm -rf vendor
	rm -f "$(ARCHIVE)"
