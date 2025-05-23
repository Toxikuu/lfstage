all: build

build:
	cargo build --release

clean:
	cargo clean

install:
	install -Dm755 target/release/lfstage  -t    $(DESTDIR)/usr/bin/
	install -Dm644 config.toml             -t    $(DESTDIR)/etc/lfstage/
	cp -af var                                   $(DESTDIR)/

uninstall:
	rm -f  $(DESTDIR)/usr/bin/lfstage            $(DESTDIR)/var/log/lfstage
	rm -rf $(DESTDIR)/etc/lfstage
	rm -rf $(DESTDIR)/var/lib/lfstage            $(DESTDIR)/var/cache/lfstage
