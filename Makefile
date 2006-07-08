version := $(shell awk '/define version/{print $$3}' netplug.spec)

prefix ?=
bindir ?= $(prefix)/sbin
etcdir ?= $(prefix)/etc/netplug
initdir ?= $(prefix)/etc/rc.d/init.d
scriptdir ?= $(prefix)/etc/netplug.d
mandir ?= $(prefix)/usr/share/man

install_opts :=

CFLAGS += -Wall -Werror -std=gnu99 -DNP_ETC_DIR='"$(etcdir)"' \
	-DNP_SCRIPT_DIR='"$(scriptdir)"' -ggdb3 -O3 -DNP_VERSION='"$(version)"'

netplugd: config.o netlink.o lib.o if_info.o main.o
	$(CC) -o $@ $^

install:
	install -d $(install_opts) -m 755 $(bindir) $(etcdir) $(scriptdir) \
		$(initdir) $(mandir)/man8
	install $(install_opts) -m 755 netplugd $(bindir)
	install $(install_opts) -m 644 etc/netplugd.conf $(etcdir)
	install $(install_opts) -m 755 scripts/netplug $(scriptdir)
	install $(install_opts) -m 755 scripts/rc.netplugd $(initdir)/netplugd
	install $(install_opts) -m 444 man/man8/netplugd.8 $(mandir)/man8

hg_root := $(shell hg root)
tar_root := netplug-$(version)
tar_file := $(hg_root)/$(tar_root).tar.bz2
files := $(shell hg locate '')

tarball: $(tar_file)

$(tar_file): $(files)
	hg archive -X '.hg*' -t tbz2 $(tar_file)

.FORCE: rpm

rpm: $(tar_file)
	mkdir -p rpm/{BUILD,RPMS/{i386,x86_64},SOURCES,SPECS,SRPMS}
	rpmbuild --define '_topdir $(shell pwd)/rpm' -ta $(tar_file)
	mv rpm/*/*.rpm rpm
	mv rpm/*/*/*.rpm rpm
	rm -rf rpm/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

fedora: $(tar_file)
	rpmbuild --define 'release 0.fdr.1' -ta $(tar_file)

clean:
	-rm -f netplugd *.o *.tar.bz2
