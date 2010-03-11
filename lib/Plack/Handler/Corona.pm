package Plack::Handler::Corona;
use strict;
use Corona::Server;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_;

    my $server = Corona::Server->new(
        host  => $self->{host}  || '*',
        user  => $self->{user}  || $>,
        group => $self->{group} || $),
        log_level => 1,
    );
    $server->{app} = $app;
    $server->run(port => $self->{port});
}

1;

__END__

=head1 NAME

Plack::Handler::Corona - Corona server adapter for Plack

=head1 SYNOPSIS

  plackup -s Corona --port 9091 app.psgi

=head1 SEE ALSO

L<Corona>

=cut
