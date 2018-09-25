package EPPlication::Client::DB;
use Moose;
use namespace::autoclean;
use MooseX::Types::Common::String qw/ NumericCode NonEmptySimpleStr /;
use DBI;

has 'client' => (
    is        => 'rw',
    isa       => 'DBI::db',
    predicate => 'has_client',
    handles   => {
        disconnect => 'disconnect',
    },
);

has 'driver' => (
    is      => 'rw',
    isa     => NonEmptySimpleStr,
    lazy    => 1,
    default => 'Pg',
);

has port => (
    is        => 'rw',
    isa       => NumericCode,
    predicate => 'has_port',
);

for my $attr (qw/ host database username password /) {
    has $attr => (
        is        => 'rw',
        isa       => NonEmptySimpleStr,
        predicate => "has_$attr",
    );
}

sub config_str {
    my ($self) = @_;
    return "dsn: " . $self->dsn . "\nusername: " . $self->username . "\npassword: " . $self->password;
}

sub dsn {
    my ($self) = @_;
    return 'dbi:'
        . $self->driver . ':'
        . 'dbname=' . $self->database . ';'
        . 'host='   . $self->host . ';'
        . 'port='   . $self->port;
}

sub connect {
    my ($self) = @_;

    die "DB client already connected.\n"
        if $self->connected;

    for my $attr (qw/ host port database username password /) {
        my $predicate = "has_$attr";
        die "db_$attr not configured.\n"
            unless $self->$predicate;
    }

    my $dbh = DBI->connect(
        $self->dsn,
        $self->username,
        $self->password,
        {
            AutoCommit     => 1,
            RaiseError     => 1,
            quote_names    => 1,
            pg_enable_utf8 => 1,
        },
    ) or die $DBI::errstr;

    $self->client($dbh);
}

sub connected {
    my ($self) = @_;
    return unless $self->has_client;
    return $self->client->ping;
}

sub request {
    my ( $self, $statement ) = @_;

    die "DB client not connected.\n"
      unless $self->connected;

    my $sth = $self->client->prepare($statement)
      or die $self->client->errstr;

    my $rv = $sth->execute
      or die $sth->errstr;

    my $num_of_fields = defined $sth->{NUM_OF_FIELDS} ? $sth->{NUM_OF_FIELDS} : 0;
    my $is_select_statement = $num_of_fields > 0 ? 1 : 0;

    if ($is_select_statement) {
        return $sth->fetchall_arrayref( {} );
    }
    else {
        my $num_rows_affected = $rv;
        return $num_rows_affected;
    }
}

__PACKAGE__->meta->make_immutable;
1;
