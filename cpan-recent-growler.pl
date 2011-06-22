#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use AnyEvent;
use Cocoa::Growl;
use Cocoa::EventLoop;
use File::Copy;
use CPAN::Recent::Uploads;
use FindBin;
use Digest::MD5 qw(md5_hex);
use LWP::Simple;

my $AppDomain = 'net.bulknews.GitHubGrowler';
my $AppName   = 'cpan-recent Growler';

my $TempDir = "$ENV{HOME}/Library/Caches/$AppDomain";
mkdir $TempDir, 0777 unless -e $TempDir;

my $AppIcon = "$TempDir/cpan.jpg";
copy "$FindBin::Bin/data/cpan.jpg", $AppIcon;

my @events = ('New release');

Cocoa::Growl::growl_register(
    app           => $AppName,
    icon          => $AppIcon,
    notifications => [ @events, 'Fatal Error', 'Error' ],
    defaults => [ @events, 'Fatal Error' ],
);

my %options = ( interval => 10000, maxGrowls => 10 );

my $t = AE::timer 0, $options{interval}, sub {
    growl_feed( \%options );
};

AE::cv->recv;

sub growl_feed {
    my ($options) = @_;
    
    my $tt = time() - ( $options->{interval} );
    my @uploads = CPAN::Recent::Uploads->recent($tt);
    
    # TODO: Gravatar
    my $icon = $AppIcon;

    my $module = 0;
    foreach my $entry (@uploads) {
        $module++;
        next if $module >= $options->{maxGrowls};

        warn $entry;
        # TODO: (...)
        my (@path) = split('/', $entry);
        my $author = $path[2];
        my $module = $path[3];

        my $cpan_email = join('@', lc($author), 'cpan.org');
        warn $cpan_email;
        my $cpan_md5 =  md5_hex($cpan_email);
        my $gravatar_url = 'http://gravatar.com/avatar/' . $cpan_md5;
        my $gravatar_file = join('/', $TempDir, $cpan_md5);
        getstore( $gravatar_url, $gravatar_file ) if ( ! -r $gravatar_file );

        Cocoa::Growl::growl_notify(
            name        => 'New release',
            title       => encode_utf8($module),
            description => encode_utf8("by $author"),
            icon        => $gravatar_file,
            on_click    => sub {
                    my $link = "http://search.cpan.org/~$author";
                    system( "open", $link );
            },
        );
    }

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

