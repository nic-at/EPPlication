package EPPlication::Step::SeleniumContent;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Util::Encode',
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier variable content_type /]),
  ;

sub process {
    my ($self) = @_;

    my $identifier_raw = $self->identifier;
    my $identifier     = $self->process_template($identifier_raw);
    my $variable     = $self->variable;
    my $content_type = $self->content_type;

    $self->add_detail("Driver identifier: $identifier");
    $self->add_detail("type: $content_type");

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    my $driver = $self->selenium_client->get_driver($identifier);

    my $content;
    if ($content_type eq 'title') {
        $content = $driver->get_title;
    }
    elsif ($content_type eq 'body_html') {
        $content = $driver->get_page_source;
    }
    elsif ($content_type eq 'body_text') {
        $content = $driver->get_body;
    }

    $self->add_detail($content);
    $self->stash_set( $variable, $content );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
