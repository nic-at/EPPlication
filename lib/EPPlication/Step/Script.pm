package EPPlication::Step::Script;

use Moose;
use EPPlication::Role::Step::Parameters;
use Encode qw/ decode_utf8 encode_utf8 /;
use IPC::Run3;

with
  'EPPlication::Role::Step::Base', Parameters(
    parameter_list => [
        qw/
          command
          var_stdout
          /
    ]
  ),
  ;

sub process {
    my ($self) = @_;

    my $command_raw  = $self->command;
    my $var_stdout   = $self->var_stdout;

    my $command  = $self->process_tt_value( 'Command', $self->command );

    my $stdout;
    my $stderr;
    $command =~ s/\r\n?/\n/g; #fix newlines: \r\n => \n
    run3($command, \undef, \$stdout, \$stderr);

    $stdout = decode_utf8($stdout);
    $stderr = decode_utf8($stderr);
    $self->add_detail("\n" . $stdout);

    die "$stderr\n" if $stderr;

    $self->stash_set( $var_stdout => $stdout );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
