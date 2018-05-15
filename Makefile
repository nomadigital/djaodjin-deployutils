# -*- Makefile -*-

-include $(buildTop)/share/dws/prefix.mk

srcDir        ?= .
installTop    ?= $(VIRTUAL_ENV)
binDir        ?= $(installTop)/bin

PYTHON        := $(binDir)/python


# We generate the SECRET_KEY this way so it can be overriden
# in test environments.
SECRET_KEY ?= $(shell $(PYTHON) -c 'import sys ; from random import choice ; sys.stdout.write("".join([choice("abcdefghijklmnopqrstuvwxyz0123456789!@\#$%^*-_=+") for i in range(50)]))' )

DJAODJIN_SECRET_KEY ?= $(shell $(PYTHON) -c 'import sys ; from random import choice ; sys.stdout.write("".join([choice("abcdefghijklmnopqrstuvwxyz0123456789!@\#$%^*-_=+") for i in range(50)]))' )

# Django 1.7,1.8 sync tables without migrations by default while Django 1.9
# requires a --run-syncdb argument.
# Implementation Note: We have to wait for the config files to be installed
# before running the manage.py command (else missing SECRECT_KEY).
RUNSYNCDB     = $(if $(findstring --run-syncdb,$(shell cd $(srcDir) && $(PYTHON) manage.py migrate --help 2>/dev/null)),--run-syncdb,)

scripts := djd

install::
	cd $(srcDir) && $(PYTHON) ./setup.py --quiet \
		build -b $(CURDIR)/build install

install-conf:: $(srcDir)/credentials

initdb: install-conf
	-rm -f $(srcDir)/db.sqlite
	cd $(srcDir) && $(PYTHON) ./manage.py migrate $(RUNSYNCDB) --noinput

$(srcDir)/credentials: $(srcDir)/testsite/etc/credentials
	[ -f $@ ] || \
		sed -e "s,\%(SECRET_KEY)s,$(SECRET_KEY)," \
			-e "s,\%(DJAODJIN_SECRET_KEY)s,$(DJAODJIN_SECRET_KEY)," \
			$< > $@

doc:
	$(installDirs) docs
	cd $(srcDir) && sphinx-build -b html ./docs $(PWD)/docs


-include $(buildTop)/share/dws/suffix.mk
