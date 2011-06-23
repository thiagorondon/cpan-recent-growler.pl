use inc::Module::Install;

name "cpan-recent-growler.pl";
all_from "cpan-recent-growler.pl";
install_script "cpan-recent-growler.pl";

requires 'Cocoa::Growl';
requires 'Cocoa::EventLoop';
requires 'AnyEvent::Impl::Cocoa';
requires 'AnyEvent::HTTP';
requires 'Digest::MD5';
requires 'LWP::Simple';
requires 'CPAN::Recent::Uploads';

WriteAll;

