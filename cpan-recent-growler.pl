#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/extlib/lib/perl5";

use Encode;
use AnyEvent;
use Cocoa::Growl;
use Cocoa::EventLoop;
use File::Copy;
use CPAN::Recent::Uploads;
use FindBin;
use Digest::MD5 qw(md5_hex);
use LWP::Simple;

use version; our $VERSION = qv("v0.1");

my $AppDomain = 'net.bulknews.CPANRecentGrowler';
my $AppName   = 'CPAN Recent Growler';

my $TempDir = "$ENV{HOME}/Library/Caches/$AppDomain";
mkdir $TempDir, 0777 unless -e $TempDir;

my $AppIcon = "$TempDir/cpan.png";
copy "$FindBin::Bin/data/cpan.png", $AppIcon;

my @events = ('New upload');

Cocoa::Growl::growl_register(
    app           => $AppName,
    icon          => $AppIcon,
    notifications => [ @events, 'Fatal Error', 'Error' ],
    defaults => [ @events, 'Fatal Error' ],
);

my %options = ( interval => 300, maxGrowls => 10, initial_interval => 86400 );
get_preferences( \%options, "initial_interval", "interval", "maxGrowls" );

growl_feed( \%options, 1 );

my $t = AE::timer 0, $options{interval}, sub {
    growl_feed( \%options );
};

AE::cv->recv;

sub growl_feed {
    my ( $options, $init ) = @_;
    $init ||= 0;

    my $tt =
      time() - ( $init ? $options->{initial_interval} : $options->{interval} );
    my @uploads = CPAN::Recent::Uploads->recent($tt);

    # TODO: Gravatar
    my $icon = $AppIcon;

    my $module = 0;
    foreach my $entry (@uploads) {
        $module++;
        next if $module >= $options->{maxGrowls};

        warn $entry;

        # TODO: (...)
        my (@path) = split( '/', $entry );
        my $author = $path[2];
        my $module = $path[3];
        
        my $cpan_email = join( '@', lc($author), 'cpan.org' );
        my $link = "http://search.cpan.org/~$author";

        warn $module;
        warn $cpan_email;
        warn $link;

        my $cpan_md5      = md5_hex($cpan_email);
        my $gravatar_url  = 'http://gravatar.com/avatar/' . $cpan_md5;
        my $gravatar_file = join( '/', $TempDir, "$cpan_md5.jpg" );
        getstore( $gravatar_url, $gravatar_file ) if ( !-r $gravatar_file );

        Cocoa::Growl::growl_notify(
            name        => 'New upload',
            title       => encode_utf8($module),
            description => encode_utf8("by $author"),
            icon        => $gravatar_file,
            on_click    => sub {
                system( "open", $link );
            },
        );
    }

}

sub get_preferences {
    my ( $opts, @keys ) = @_;

    for my $key (@keys) {
        my $value = read_preference($key);
        $opts->{$key} = $value if defined $value;
    }
}

sub read_preference {
    my $key = shift;

    no warnings 'once';
    open OLDERR, ">&STDERR";
    open STDERR, ">/dev/null";
    my $value = `defaults read $AppDomain $key`;
    open STDERR, ">&OLDERR";

    return if $value eq '';
    chomp $value;
    return $value;
}

__END__

=head1 NAME

cpan-recent-growler

=head1 AUTHOR

Thiago Rondon

=head1 ACKNOWLEDGE

Tatsuhiko Miyagawa, for github-crowler.pl

=head1 LICENSE

This program is licensed under the same terms as Perl itself.

=cut

