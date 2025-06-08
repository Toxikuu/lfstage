all: build

build:
	cargo build --release

clean:
	cargo clean

check: test
	cargo clippy
	cargo audit

# The tests should be run as root
test:
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m The test suite assumes LFStage is installed"                 >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m It also makes assumptions about the environment it's run in" >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m Lastly, it's meant to be run by the maintainer"              >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m In other words, take test failures with a grain of salt"     >&2
	@sleep 1
	@if cargo --list | grep -q nextest; then cargo nextest run; else cargo test; fi

install: var
	install -Dm755 target/release/lfstage  -t    $(DESTDIR)/usr/bin/
	cp -af usr                                   $(DESTDIR)/
	cp -af etc                                   $(DESTDIR)/

uninstall:
	rm -f  $(DESTDIR)/usr/bin/lfstage
	rm -rf $(DESTDIR)/etc/lfstage                $(DESTDIR)/usr/lib/lfstage
	rm -rf $(DESTDIR)/var/lib/lfstage            $(DESTDIR)/var/cache/lfstage
	rm -rf $(DESTDIR)/var/log/lfstage            $(DESTDIR)/tmp/lfstage

var:
	install -dm755 $(DESTDIR)/var/lib/lfstage/mount        \
	               $(DESTDIR)/var/lib/lfstage/profiles     \
	               $(DESTDIR)/var/cache/lfstage/profiles   \
	               $(DESTDIR)/var/cache/lfstage/stages

.PHONY: all build clean check test install uninstall var
