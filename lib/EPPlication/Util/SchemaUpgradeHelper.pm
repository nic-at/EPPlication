package EPPlication::Util::SchemaUpgradeHelper;
use strict;
use warnings;
use Exporter qw/ import /;
use JSON::PP qw//;
use feature qw/ say /;

our %EXPORT_TAGS = (
    all => [
        qw/
          get_params
          set_params
          add_param
          rename_param
          delete_param
          change_param
          /
    ]
);
Exporter::export_ok_tags('all');

sub get_params {
    my ($step)     = @_;
    my $params_raw = $step->get_column('parameters');
    my $params     = JSON::PP->new->decode($params_raw);
    return $params;
}

sub set_params {
    my ( $step, $params ) = @_;
    $step->set_column( 'parameters' => JSON::PP->new->encode($params) );
    $step->update();
}

sub add_param {
    my ( $params, $key, $value ) = @_;
    say "Adding '$key' => '$value'";
    $params->{$key} = $value;
}

sub rename_param {
    my ( $params, $old_key, $new_key ) = @_;
    say "Rename '$old_key' > '$new_key'";
    $params->{$new_key} = delete $params->{$old_key};
}

sub delete_param {
    my ( $params, $key ) = @_;
    say "Deleting '$key'";
    delete $params->{$key};
}

sub change_param {
    my ( $params, $key, $old, $new ) = @_;
    if ($params->{$key} eq $old) {
        say "Change '$key:' '$old' => '$new'";
        $params->{$key} = $new;
    }
}

1;
