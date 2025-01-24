LIBEXECDIR=/usr/libexec/obsbugzilla
LIBEXECDIR2=${DESTDIR}${LIBEXECDIR}

build:
	echo "this is pure perl - nothing to build"

test:
	prove -v

install:
	mkdir -p ${LIBEXECDIR2} \
                ${DESTDIR}/var/lib/obsbugzilla/queue/ \
	        ${DESTDIR}/usr/lib/systemd/system/
	install -m 755 sourceobs.pl sink.pl sourcerabbit.pl sourcerabbit-wrapper.sh opensuserabbit.py cleanup.sh checkobscronjob updatejiraprojects.sh ${LIBEXECDIR2}/
	install -m 644 *.pm ${LIBEXECDIR2}/
	install -m 644 package/*.service package/*.timer ${DESTDIR}/usr/lib/systemd/system/
	sed -i -e 's,/usr/libexec/obsbugzilla,${LIBEXECDIR},g' ${DESTDIR}/usr/lib/systemd/system/obsbugzilla*.service ${LIBEXECDIR2}/*.pl
	cp -a extractchanges source sink  ${LIBEXECDIR2}/
	ln -s /var/lib/obsbugzilla/ ${LIBEXECDIR2}/data
	ln -s /var/lib/obsbugzilla/queue ${LIBEXECDIR2}/queue
