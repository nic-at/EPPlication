package EPPlication::Web::Form::User;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class' => ( default => 'User' );

has_field 'name' => (
    type     => 'Text',
    required => 1,
    unique   => 1,
    apply    => [
        {   check   => qr/^[a-zA-Z][a-zA-Z0-9]*$/xms,
            message => 'name does not match /^~[a-zA-Z~]~[a-zA-Z0-9~]*$/',
        }
    ],
);

has_field 'password' => (
    type     => 'Password',
    required => 1,
    inactive => 1,
    apply    => [
        {   check => sub { return length($_[0]) >= 8; },
            message => 'at least 8 characters',
        }
    ],
);

has_field 'password_repeat' => (
    type     => 'PasswordConf',
    required => 1,
    inactive => 1,
);

has_field 'edit_with_password' => (
    type     => 'Display',
    inactive => 1,
);

sub html_edit_with_password {
    my ( $self, $field ) = @_;
    my $user_id = $self->item->id;
    my $html    = <<"HERE";
<div class="form-group">
  <label for="edit_with_password" class="control-label col-lg-2">Password</label>
  <div class="col-lg-10">
    <a class="btn btn-info btn-sm" href="/user/$user_id/edit_with_password">edit</a>
  </div>
</div>
HERE
    return $html;
}

has_field 'roles' => (
    type   => 'Multiple',
    widget => 'CheckboxGroup',
);

has_field 'submit' => ( type => 'Submit', value => 'Submit' );

1;
