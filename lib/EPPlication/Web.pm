package EPPlication::Web;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
our $VERSION = '1.0.10';

use Catalyst qw/
    ConfigLoader
    StackTrace
    Static::Simple
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    +CatalystX::SimpleLogin
    Authentication
    Authorization::Roles
/;

use EPPlication::InitLogger;
use Log::Any qw/$log/;
__PACKAGE__->log($log);

extends 'Catalyst';

my $js_home = __PACKAGE__->path_to(qw/ root static js /);
my @js_files = (
    "$js_home/jquery.js",
    "$js_home/jquery-ui.js",
    "$js_home/bootstrap.js",
    "$js_home/knockout.js",
    "$js_home/knockout-sortable.js",
    "$js_home/knockout.persist.js",
    "$js_home/JSONEditor.js",
    "$js_home/treejo.js",
    "$js_home/vm/test.js",
    "$js_home/vm/tag.js",
    "$js_home/vm/step.js",
    "$js_home/vm/step_edit.js",
    "$js_home/vm/user.js",
    "$js_home/vm/job.js",
    "$js_home/vm/job_show.js",
    "$js_home/main.js",
);
my $css_home = __PACKAGE__->path_to(qw/ root static css /);
my @css_files = (
    "$css_home/bootstrap.css",
    "$css_home/treejo.css",
    "$css_home/main.css",
);

__PACKAGE__->config(
    name                                        => 'EPPlication::Web',
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1,                        # Send X-Catalyst header
    'Plugin::Session'      => { flash_to_stash => 1 },
    psgi_middleware        => [
        'XSendfile',
        'Assets' => {
            type => 'js',
            files => \@js_files,
        },
        'Assets' => {
            type => 'css',
            files => \@css_files,
        },
    ],
    'View::HTML' => {
        INCLUDE_PATH => [ __PACKAGE__->path_to(qw/ root templates /)->stringify ],
        WRAPPER  => 'wrapper.tt',
        ENCODING => 'utf-8',
    },
    'Plugin::Authentication' => {
        default => {
            store => {
                class         => 'DBIx::Class',
                user_model    => 'DB::User',
                role_relation => 'roles',
                role_field    => 'name',
            },
            credential => {
                class          => 'Password',
                password_field => 'password',
                password_type  => 'self_check',
            },
        },
    },
    'Controller::Login' => {
        login_form_args => {
            authenticate_username_field_name => 'name',
            field_list => [ remember => { inactive => 1 } ],
        },
        login_form_class_roles => ['EPPlication::Web::Role::Form'],
    },
);

__PACKAGE__->setup();

=head1 AUTHOR

David Schmidt <david.schmidt@univie.ac.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by the University of Vienna.

See LICENSE for the complete licensing terms.

=cut

1;
