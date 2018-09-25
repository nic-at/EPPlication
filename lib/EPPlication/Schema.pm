package EPPlication::Schema;
use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

our $VERSION = 60;
__PACKAGE__->mk_group_accessors(simple => qw/ job_export_dir subtest_types /);
__PACKAGE__->load_namespaces();

1;
