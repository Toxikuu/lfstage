all: build

build:
	cargo build --release

clean:
	cargo clean

test:
	@echo -e "\x1b[37;1m[\x1b[31mWARNING\x1b[37m]\x1b[0m The test suite assumes LFStage is installed" >&2
	@sleep 1
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
	rm -rf $(DESTDIR)/var/log/lfstage
