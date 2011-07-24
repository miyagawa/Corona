package Plack::Handler::Corona::Server;
use strict;
use base 'Corona::Server';

sub pre_loop_hook {
    my $self = shift;
    $self->SUPER::pre_loop_hook(@_);

    my $s = $self->{server};
    $s->{_server_ready}->({
        host => $s->{host}[0],
        port => $s->{port}[0],
        server_software => 'Corona',
    });
}

package Plack::Handler::Corona;
use strict;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_;

    my $server = Plack::Handler::Corona::Server->new(
        host  => $self->{host}  || '*',
        user  => $self->{user}  || $>,
        group => $self->{group} || $),
        log_level => 1,
        _server_ready => $self->{server_ready} || sub {},
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
