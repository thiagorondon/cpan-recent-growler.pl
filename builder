#!/bin/sh
VERSION=`perl -lne '/qv\("(v[\d\.]+)"\)/ and print $1' cpan-recent-growler.pl`
echo "Building CPAN Recent Growler $VERSION"

rm -rf "CPAN Recent.app"

# bundle extra libraries into extlib
/usr/bin/perl -S cpanm -L extlib --notest --installdeps .

# Build .app
/opt/local/var/macports/build/_opt_local_var_macports_sources_rsync.macports.org_release_ports_aqua_Platypus/work/Platypus-4.4-Source/build/platypus -a 'CPAN Recent Growler' \
-o None \
-u "Thiago Rondon" \
-p /usr/bin/perl \
-s '????' \
-i appIcon.icns \
-I net.bulknews.CPANRecentGrowler \
-N "APP_BUNDLER=Platypus-4.0" \
-f data/cpan.png \
-f extlib \
-c cpan-recent-growler.pl \
-V $VERSION ./CPAN\ Recent\ Growler.app
echo

# Build.zip
zip -r CPAN-Recent-Growler-$VERSION.zip "CPAN Recent Growler.app" > /dev/null
echo "CPAN-Recent-$VERSION.zip created"

