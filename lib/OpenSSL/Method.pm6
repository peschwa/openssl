module OpenSSL::Method;

use NativeCall;

class SSL_METHOD is repr('CStruct') {
    has int32 $.version;
}

our sub SSLv2_client_method() returns SSL_METHOD is native('libssl')  { * }
our sub SSLv2_server_method() returns SSL_METHOD is native('libssl')  { * }
our sub SSLv2_method() returns SSL_METHOD is native('libssl')         { * }
our sub SSLv3_client_method() returns SSL_METHOD is native('libssl')  { * }
our sub SSLv3_server_method() returns SSL_METHOD is native('libssl')  { * }
our sub SSLv3_method() returns SSL_METHOD is native('libssl')         { * }
our sub SSLv23_client_method() returns SSL_METHOD is native('libssl') { * }
our sub SSLv23_server_method() returns SSL_METHOD is native('libssl') { * }
our sub SSLv23_method() returns SSL_METHOD is native('libssl')        { * }
our sub TLSv1_client_method() returns SSL_METHOD is native('libssl')  { * }
our sub TLSv1_server_method() returns SSL_METHOD is native('libssl')  { * }
our sub TLSv1_method() returns SSL_METHOD is native('libssl')         { * }
