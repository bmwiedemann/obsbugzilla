LIBEXEC=${DESTDIR}/usr/libexec/obsbugzilla

build:
	echo "this is pure perl - nothing to build"

test:
	prove -v

install:
	mkdir -p ${LIBEXEC} \
                ${DESTDIR}/var/lib/obsbugzilla/queue/ \
	        ${DESTDIR}/usr/lib/systemd/system/
	install -m 755 sourceobs.pl sink.pl sourcerabbit.pl sourcerabbit-wrapper.sh opensuserabbit.py ${LIBEXEC}/
	install -m 644 *.pm ${LIBEXEC}/
	install -m 644 package/*.service package/*.timer ${DESTDIR}/usr/lib/systemd/system/
	cp -a source sink ${LIBEXEC}/
	ln -s /var/lib/obsbugzilla/ ${LIBEXEC}/data
	ln -s data/queue ${LIBEXEC}/queue
