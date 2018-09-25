package EPPlication::Web::Form::Tag;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class' => ( default => 'Tag' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    apply    => [
        {   check   => qr/^\w+$/xms,
            message => 'Only alphanumeric characters allowed.',
        }
    ],
);
has_field 'color' => (
    type     => 'Text',
    required => 1,
    apply    => [
        {   check   => qr/^\#[a-fA-F]{6}$/xms,
            message => 'Not a bright color code. (e.g.: #aaaaaa - #bbbbbb)',
        }
    ],
);
has_field 'submit' => ( type => 'Submit' );

1;
