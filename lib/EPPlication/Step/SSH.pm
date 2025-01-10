package EPPlication::Step::SSH;

use Moose;
use Net::OpenSSH;
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

    my $ssh = Net::OpenSSH->new(
              $ssh_host,
              user     => $ssh_user,
              port     => $ssh_port,
              key_path => $self->ssh_private_key_path->stringify,
              timeout  => 10, # 10 seconds
              master_opts => [
                  -o => 'StrictHostKeyChecking no',
                  -o => 'PasswordAuthentication no',
                  -o => 'IdentitiesOnly yes',
                  -o => 'IdentityFile ' . $self->ssh_private_key_path->stringify,
                  -F => '/dev/null',
              ],
              forward_agent => 0,
              forward_X11 => 0,
    );

    if ($ssh->error) {
        die "Couldn't establish SSH connection: ". $ssh->error;
    }

    my ($stdout, $stderr) = $ssh->capture2($command);
    #my ($stdout, $stderr) = exec_command($ssh, encode_utf8($command));
    #$stdout = decode_utf8($stdout);
    #$stderr = decode_utf8($stderr);
    $self->add_detail("\n" . $stdout);

    die $stderr if $stderr;

    $self->stash_set( $var_stdout => $stdout );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
