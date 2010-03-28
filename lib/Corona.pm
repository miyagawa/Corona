package Corona;
use strict;
use 5.008_001;
our $VERSION = '0.1004';

__END__

=head1 NAME

Corona - Coro based PSGI web server

=head1 SYNOPSIS

  corona --listen :9090 app.psgi

=head1 DESCRIPTION

Corona is a Coro based Plack web server. It uses L<Net::Server::Coro>
under the hood, which means we have coroutines (threads) for each
socket, active connections and a main loop.

Because it's Coro based your web application can actually block with
I/O wait as long as it yields when being blocked, to the other
coroutine either explicitly with C<cede> or automatically (via Coro::*
magic).

  # your web application
  use Coro::LWP;
  my $content = LWP::Simple::get($url); # this yields to other threads when IO blocks

Corona also uses L<Coro::AIO> (and L<IO::AIO>) if available, to send
the static filehandle using sendfile(2).

The simple benchmark shows this server gives 2000 requests per second
in the simple Hello World app, and 300 requests to serve 2MB photo
files when used with AIO modules. Brilliantly fast.

This web server sets C<psgi.multithread> env var on.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<Coro> L<Net::Server::Coro> L<Coro::AIO>

=cut
