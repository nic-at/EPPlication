package EPPlication::Step::VarCheckRegExp;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters( parameter_list => [qw/ value regexp modifiers /] ),
  ;

sub process {
    my ($self) = @_;

    my $value      = $self->process_tt_value( 'Value', $self->value );
    my $regexp     = $self->process_tt_value( 'RegExp', $self->regexp, { between => ': /', after => '/' } );
    my $modifiers  = $self->process_tt_value( 'Modifiers', $self->modifiers );

    if ( $value =~ m/(?$modifiers)$regexp/ ) {
        $self->status('success');
    } else {
        $self->status('error');
    }

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
