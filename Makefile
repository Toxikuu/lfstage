all: build

build:
	cargo build --release

clean:
	cargo clean

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
