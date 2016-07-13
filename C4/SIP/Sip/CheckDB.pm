package C4::SIP::Sip::CheckDB;

use C4::Context;
use base qw( Exporter );


our @EXPORT = ( is_database_ok );


sub is_database_ok {

    my $dbh = C4::Context->dbh;

    my $r = $dbh->ping();

    if ($r) { # default is '0 but true'
        return 1;
    }
    return;
}
1;
