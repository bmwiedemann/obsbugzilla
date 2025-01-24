#
# spec file for package obsbugzilla
#
# Copyright (c) 2022 Bernhard M. Wiedemann / SUSE LLC
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           obsbugzilla
Version:        1.0.0
Release:        0
Summary:        Bot code to inform bugzilla+jira users about SRs
License:        GPL-2.0+
Url:            https://github.com/bmwiedemann/obsbugzilla
Group:          Tools
BuildArch:      noarch
Source0:        https://github.com/bmwiedemann/obsbugzilla/archive/refs/tags/v%version.tar.gz#/%name-%version.tar.gz
BuildRequires:  shadow
Requires:       perl-SOAP-Lite perl-XMLRPC-Lite perl-JSON-XS perl-LWP-Protocol-https perl-MLDBM python-pika osc
Requires(pre):  %{_sbindir}/useradd
Requires(pre):  group(nogroup)
Provides:       user(obsbugzilla)

%description
OBS Submit-Requests(SR) will be detected via rabbit or API query
and Jira+Bugzilla issues mentioned will be updated by the bot.

%prep
%autosetup -p1

%build

%install
make install DESTDIR=%{buildroot}

%check
#make test

%pre
if ! %{_bindir}/getent passwd obsbugzilla >/dev/null; then
   %{_sbindir}/useradd -r -c "Daemon user for obsbugzilla bot" -g nogroup -s /bin/sh \
   -d %{_localstatedir}/lib/obsbugzilla obsbugzilla
fi

%files
%doc README
%license COPYING
%{_libexecdir}/obsbugzilla
%{_unitdir}/obsbugzilla-rabbit.service
%{_unitdir}/obsbugzilla-sink.*
%{_unitdir}/obsbugzilla-sourceobs.*
#{_datadir}/%name
%attr(755,obsbugzilla,root) %{_localstatedir}/lib/%name

%changelog
