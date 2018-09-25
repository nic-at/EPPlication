package EPPlication::Web::Role::Form;
use Moose::Role;
use namespace::autoclean;

with 'HTML::FormHandler::Widget::Theme::Bootstrap3';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    $args->{is_html5}       = 1;
    return $args;
};

sub build_form_tags {
    {
        'layout_classes' => {
            label_class                    => ['col-lg-2'],
            element_wrapper_class          => ['col-lg-10'],
            no_label_element_wrapper_class => ['col-lg-offset-2'],
        },
    };
}

1;
