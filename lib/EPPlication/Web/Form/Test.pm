package EPPlication::Web::Form::Test;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class' => ( default => 'Test' );

my $re = qr/^[\ \w\-\(\):]+$/xms;
has_field 'name' => (
    type     => 'Text',
    required => 1,
    unique   => 1,
    apply    => [
        {   check   => $re,
            message => "Contains invalid characters.",
        }
    ],
);
has_field 'tags' => (
    type   => 'Multiple',
    widget => 'CheckboxGroup',
);
has_field 'submit' => ( type => 'Submit' );

1;
