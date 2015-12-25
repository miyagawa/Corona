# NAME

Corona - Coro based PSGI web server

# SYNOPSIS

    corona --listen :9090 app.psgi

# DESCRIPTION

Corona is a Coro based Plack web server. It uses [Net::Server::Coro](https://metacpan.org/pod/Net::Server::Coro)
under the hood, which means we have coroutines (threads) for each
socket, active connections and a main loop.

Because it's Coro based your web application can actually block with
I/O wait as long as it yields when being blocked, to the other
coroutine either explicitly with `cede` or automatically (via Coro::\*
magic).

    # your web application
    use Coro::LWP;
    my $content = LWP::Simple::get($url); # this yields to other threads when IO blocks

Corona also uses [Coro::AIO](https://metacpan.org/pod/Coro::AIO) (and [IO::AIO](https://metacpan.org/pod/IO::AIO)) if available, to send
the static filehandle using sendfile(2).

The simple benchmark shows this server gives 2000 requests per second
in the simple Hello World app, and 300 requests to serve 2MB photo
files when used with AIO modules. Brilliantly fast.

This web server sets `psgi.multithread` env var on.

# AUTHOR

Tatsuhiko Miyagawa

# LICENSE

This module is licensed under the same terms as Perl itself.

# SEE ALSO

[Coro](https://metacpan.org/pod/Coro) [Net::Server::Coro](https://metacpan.org/pod/Net::Server::Coro) [Coro::AIO](https://metacpan.org/pod/Coro::AIO)
