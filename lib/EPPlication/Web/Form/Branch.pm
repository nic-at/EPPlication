package EPPlication::Web::Form::Branch;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class' => ( default => 'Branch' );

my $re = qr/^[a-zA-Z0-9_.-]+$/xms;
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
has_field 'submit' => ( type => 'Submit' );

1;
