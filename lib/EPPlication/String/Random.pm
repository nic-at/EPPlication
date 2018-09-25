package EPPlication::String::Random;

use strict;
use warnings;
use String::Random qw/ random_regex /;
use Exporter qw/ import /;
our @EXPORT_OK = qw/ rand_regex /;

# String::Random 0.26 prints a warning for some characters that
# usually have a special meaning in a regular expression.
# Because I do not want to flood the logs with these warnings
# are silenced.
# see https://rt.cpan.org/Public/Bug/Display.html?id=86894

sub rand_regex {
    my ($pattern) = @_;
    local $SIG{__WARN__} = sub {
        return if $_[0] =~ m/^'.'\ will\ be\ treated\ literally\ inside\ \[\]/xms;
        CORE::warn($_[0]);
    };
    random_regex($pattern);
}

1;
