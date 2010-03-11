package Corona::Server;
use strict;
use 5.008_001;

use base qw( Net::Server::Coro );
use Plack::Util;

use constant HAS_AIO => !$ENV{PLACK_NO_SENDFILE} && eval "use Coro::AIO; 1";

use HTTP::Status;
use Scalar::Util;
use List::Util qw(sum max);
use Plack::HTTPParser qw( parse_http_request );
use constant MAX_REQUEST_SIZE => 131072;

sub process_request {
    my $self = shift;

    my $fh = $self->{server}{client};

    my $env = {
        SERVER_PORT => $self->{server}{port}[0],
        SERVER_NAME => $self->{server}{host}[0],
        SCRIPT_NAME => '',
        REMOTE_ADDR => $self->{server}{peeraddr},
        'psgi.version' => [ 1, 0 ],
        'psgi.errors'  => *STDERR,
        'psgi.input'   => $self->{server}{client},
        'psgi.url_scheme' => 'http', # SSL support?
        'psgi.nonblocking'  => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.multithread'  => Plack::Util::TRUE,
        'psgi.multiprocess' => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgix.io'          => $fh->fh,
    };

    my $res = [ 400, [ 'Content-Type' => 'text/plain' ], [ 'Bad Request' ] ];

    my $buf = '';
    while (1) {
        my $read = $fh->readline("\015\012\015\012")
            or last;
        $buf .= $read;

        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            $res = Plack::Util::run_app $self->{app}, $env;
            last;
        } elsif ($reqlen == -2) {
            # incomplete, continue
        } else {
            last;
        }
    }

    if (ref $res eq 'ARRAY') {
        # PSGI standard
        $self->_write_response($res, $fh);
    } elsif (ref $res eq 'CODE') {
        # delayed return
        my $cb = Coro::rouse_cb;
        $res->(sub {
            $self->_write_response(shift, $fh, $cb);
        });
        Coro::rouse_wait $cb;
    }
}

sub _write_response {
    my($self, $res, $fh, $rouse_cb) = @_;

    my (@lines, $conn_value);

    while (my ($k, $v) = splice(@{$res->[1]}, 0, 2)) {
        push @lines, "$k: $v\015\012";
        if (lc $k eq 'connection') {
            $conn_value = $v;
        }
    }

    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\015\012";
    push @lines, "\015\012";

    $fh->syswrite(join '', @lines);

    if (!defined $res->[2]) {
        # streaming write
        return Plack::Util::inline_object
            write => sub { $fh->syswrite(join '', @_) },
            close => $rouse_cb;
    } elsif (HAS_AIO && Plack::Util::is_real_fh($res->[2])) {
        my $length = -s $res->[2];
        my $offset = 0;
        while (1) {
            my $sent = aio_sendfile( $fh->fh, $res->[2], $offset, $length - $offset );
            $offset += $sent if $sent > 0;
            last if $offset >= $length;
        }
    } else {
        Plack::Util::foreach($res->[2], sub { $fh->syswrite(join '', @_) });
    }

    $rouse_cb->() if $rouse_cb;
}

1;

__END__
