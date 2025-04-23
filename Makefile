all: build

build:
	cargo build --release

clean:
	cargo clean

install:
	install -Dm755 target/release/lfstage  -t    $(DESTDIR)/usr/bin/
	install -Dm644 config.toml             -t    $(DESTDIR)/etc/lfstage/
	find scripts -type f -exec install -Dm755 {} $(DESTDIR)/usr/share/lfstage/{} \;
	install -Dm644 $(wildcard envs/*)      -t    $(DESTDIR)/usr/share/lfstage/envs/
	install -dm755                               $(DESTDIR)/var/tmp/lfstage/stages
	install -dm755                               $(DESTDIR)/var/tmp/lfstage/sources

uninstall:
	rm -f  $(DESTDIR)/usr/bin/lfstage          $(DESTDIR)/var/log/lfstage
	rm -rf $(DESTDIR)/etc/lfstage              $(DESTDIR)/usr/share/lfstage
	rm -rf $(DESTDIR)/mnt/lfstage              $(DESTDIR)/var/tmp/lfstage
