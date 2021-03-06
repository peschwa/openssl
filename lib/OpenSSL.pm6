class OpenSSL;

use OpenSSL::SSL;

use NativeCall;
use libbuf;

has OpenSSL::Ctx::SSL_CTX $.ctx;
has OpenSSL::SSL::SSL $.ssl;
has $.client;

method new(Bool :$client = False, Int :$version?) {
    OpenSSL::SSL::SSL_library_init();
    OpenSSL::SSL::SSL_load_error_strings();

    my $method;
    if $version.defined {
        given $version {
            when 2 {
                $method = ($client ?? OpenSSL::Method::SSLv2_client_method() !! OpenSSL::Method::SSLv2_server_method());
            }
            when 3 {
                $method = ($client ?? OpenSSL::Method::SSLv3_client_method() !! OpenSSL::Method::SSLv3_server_method());
            }
            default {
                $method = ($client ?? OpenSSL::Method::TLSv1_client_method() !! OpenSSL::Method::TLSv1_server_method());
            }
        }
    }
    else {
        $method = $client ?? OpenSSL::Method::TLSv1_client_method() !! OpenSSL::Method::TLSv1_server_method();
    }
    my $ctx     = OpenSSL::Ctx::SSL_CTX_new( $method );
    my $ssl     = OpenSSL::SSL::SSL_new( $ctx );

    self.bless(:$ctx, :$ssl, :$client);
}

method set-fd(int32 $fd) {
    OpenSSL::SSL::SSL_set_fd($!ssl, $fd);
}

method set-connect-state {
    OpenSSL::SSL::SSL_set_connect_state($!ssl);
}

method set-accept-state {
    OpenSSL::SSL::SSL_set_accept_state($!ssl);
}

method connect {
    OpenSSL::SSL::SSL_connect($!ssl);
}

method accept {
    OpenSSL::SSL::SSL_accept($!ssl);
}

method write(Str $s) {
    my int32 $n = $s.chars;
    OpenSSL::SSL::SSL_write($!ssl, str-to-carray($s), $n);
}

method read(Int $n, Bool :$bin) {
    my int32 $count = $n;
    my $carray = get_buf($count);
    my $read = OpenSSL::SSL::SSL_read($!ssl, $carray, $count);

    my $buf = buf8.new($carray[^$read]) if $bin.defined;

    return $bin.defined ?? $buf !! $carray[^$read]>>.chr.join;
}

method use-certificate-file(Str $file) {
    # only PEM file so far : TODO : more file types
    if OpenSSL::Ctx::SSL_CTX_use_certificate_file($!ctx, $file, 1) <= 0 {
        die "Failed to set certificate file";
    }
}

method use-privatekey-file(Str $file) {
    # only PEM file so far : TODO : more file types
    if OpenSSL::Ctx::SSL_CTX_use_PrivateKey_file($!ctx, $file, 1) <= 0 {
        die "Failed to set PrivateKey file";
    }
}

method check-private-key {
    unless OpenSSL::Ctx::SSL_CTX_check_private_key($!ctx) {
        die "Private key does not match the public certificate";
    }
}

method shutdown {
    OpenSSL::SSL::SSL_shutdown($.ssl);
}

method ctx-free {
    OpenSSL::Ctx::SSL_CTX_free($!ctx);
}

method ssl-free {
    OpenSSL::SSL::SSL_free($!ssl);
}

method close {
    until self.shutdown {};
    self.ssl-free;
    self.ctx-free;
    1;
}

sub get_buf(int32) returns CArray[uint8] { * }
trait_mod:<is>(&get_buf, :native(libbuf::library));

sub str-to-carray(Str $s) {
    my @s = $s.split('');
    my $c = CArray[uint8].new;
    for 0 ..^ $s.chars -> $i {
        my uint8 $elem = @s[$i].ord;
        $c[$i] = $elem;
    }
    $c;
}

=begin pod

=head1 NAME

OpenSSL - OpenSSL bindings

=head1 SYNOPSIS

    use OpenSSL;
    my $openssl = OpenSSL.new;
    $openssl.set-fd(123);
    $openssl.write("GET / HTTP/1.1\r\nHost: somehost\r\n\r\n");

=head1 DESCRIPTION

A module which provides OpenSSL bindings, making us able to set up a TLS/SSL connection.

=head1 METHODS

=head2 method new

    method new(Bool :$client = False, Int :$version?)

A constructor. Initializes OpenSSL library, sets method and context.

=head2 method set-fd

    method set-fd(OpenSSL:, int32 $fd)

Assings connection's file descriptor (file handle) $fd to the SSL object.

To get the $fd we should use C to set up the connection. (See L<NativeCall>)
I hope we will be able to use Perl 6's IO::Socket module instead of
connecting through C soon-ish.

=head2 method set-connect-state

    method set-connect-state(OpenSSL:)

Sets SSL object to connect (client) state.

Use it when you want to connect to SSL servers.

=head2 method set-accept-state

    method set-accept-state(OpenSSL:)

Sets SSL object to accept (server) state.

Use it when you want to provide an SSL server.

=head2 method connect

    method connect(OpenSSL:)

Connects to the server using $fd (passed using .set-fd).

Does all the SSL stuff like handshaking.

=head2 method accept

    method accept(OpenSSL:)

Accepts new client connection.

Does all the SSL stuff like handshaking.

=head2 method write

    method write(OpenSSL:, Str $s)

Sends $s to the other side (server/client).

=head2 method read

    method read(OpenSSL:, Int $n, Bool :$bin)

Reads $n bytes from the other side (server/client).

Bool :$bin if we want it to return Buf instead of Str.

=head2 method use-certificate-file

    method use-certificate-file(OpenSSL:, Str $file)

Assings a certificate (from file) to the SSL object.

=head2 method use-privatekey-file

    method use-privatekey-file(OpenSSL:, Str $file)

Assings a private key (from file) to the SSL object.

=head2 method check-private-key

    method check-private-key(OpenSSL:)

Checks if private key is valid.

=head2 method shutdown

    method shutdown(OpenSSL:)

Turns off the connection.

=head2 method ctx-free

    method ctx-free(OpenSSL:)

Frees C's SSL_CTX struct.

=head2 method ssl-free

    method ssl-free(OpenSSL:)

Frees C's SSL struct.

=head2 method close

    method close(OpenSSL:)

Closes the connection.

Unlike .shutdown it calls ssl-free, ctx-free, and then it shutdowns.

=head1 SEE ALSO

L<IO::Socket::SSL>

=end pod
