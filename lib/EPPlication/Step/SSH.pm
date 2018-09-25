package EPPlication::Step::SSH;

use Moose;
use Net::SSH2;
use EPPlication::Role::Step::Parameters;
use Encode qw/ decode_utf8 encode_utf8 /;

with
  'EPPlication::Role::Step::Base', Parameters(
    parameter_list => [
        qw/
          command
          var_stdout
          ssh_user
          ssh_host
          ssh_port
          /
    ]
  ),
  'EPPlication::Role::Step::SSHKeyPaths',
  ;

sub process {
    my ($self) = @_;

    my $command_raw  = $self->command;
    my $ssh_host_raw = $self->ssh_host;
    my $ssh_port_raw = $self->ssh_port;
    my $ssh_user_raw = $self->ssh_user;
    my $var_stdout   = $self->var_stdout;

    my $command  = $self->process_tt_value( 'Command', $self->command );
    my $ssh_host = $self->process_tt_value( 'SSH Host', $self->ssh_host );
    my $ssh_port = $self->process_tt_value( 'SSH Port', $self->ssh_port );
    my $ssh_user = $self->process_tt_value( 'SSH User', $self->ssh_user );

    my $ssh = Net::SSH2->new(timeout => 10*1000); # 10 seconds

    $ssh->connect($ssh_host, $ssh_port)
      or $ssh->die_with_error;

    $ssh->auth_publickey(
        $ssh_user,
        $self->ssh_public_key_path->stringify,
        $self->ssh_private_key_path->stringify,
    ) or $ssh->die_with_error;

    my ($stdout, $stderr) = exec_command($ssh, encode_utf8($command));
    $stdout = decode_utf8($stdout);
    $stderr = decode_utf8($stderr);
    $self->add_detail("\n" . $stdout);

    die $stderr if $stderr;

    $self->stash_set( $var_stdout => $stdout );

    return $self->result;
}

sub exec_command {
    my ($ssh, $command) = @_;

    $ssh->blocking(1);
    my $chan = $ssh->channel();
    $chan->exec($command) or die "Couldn't execute command. ($command)";
    $ssh->blocking(0);

    my $stdout = '';
    my $stderr = '';
    my @poll = { handle => $chan, events => [qw/in err/] };

    while (1) {
        $ssh->poll( 250, \@poll );
        while ( $chan->read( my $chunk, 80 ) ) { $stdout .= $chunk; }
        while ( $chan->read( my $chunk, 80, 1 ) ) { $stderr .= $chunk; }
        last if $chan->eof;
    }
    return ($stdout, $stderr);
}

__PACKAGE__->meta->make_immutable;
1;
