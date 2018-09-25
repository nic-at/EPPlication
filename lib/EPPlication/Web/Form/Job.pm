package EPPlication::Web::Form::Job;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class'   => ( default => 'Job' );
has_field 'comment' => ( type    => 'TextArea' );
has_field 'sticky'  => ( type    => 'Boolean' );
has_field 'type' => (
    type         => 'Select',
    empty_select => 'Select ...',
    required     => 1,
    options => [ map { { value => $_, label => $_ } } qw/ test temp / ],
);
has_field 'submit'  => ( type    => 'Submit' );

1;
