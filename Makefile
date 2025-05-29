all: build

build:
	cargo build --release

clean:
	cargo clean

check: test

test:
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m The test suite assumes LFStage is installed"                 >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m It also makes assumptions about the environment it's run in" >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m Lastly, it's meant to be run by the maintainer"              >&2
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m In other words, take test failures with a grain of salt"     >&2
	@sleep 4
	cargo test

install:
	install -Dm755 target/release/lfstage  -t    $(DESTDIR)/usr/bin/
	cp -af usr                                   $(DESTDIR)/
	cp -af var                                   $(DESTDIR)/
	cp -af etc                                   $(DESTDIR)/

uninstall:
	rm -f  $(DESTDIR)/usr/bin/lfstage
	rm -rf $(DESTDIR)/etc/lfstage                $(DESTDIR)/usr/lib/lfstage
	rm -rf $(DESTDIR)/var/lib/lfstage            $(DESTDIR)/var/cache/lfstage
	rm -rf $(DESTDIR)/var/log/lfstage            $(DESTDIR)/tmp/lfstage
