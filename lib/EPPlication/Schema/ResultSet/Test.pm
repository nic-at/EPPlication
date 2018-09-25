package EPPlication::Schema::ResultSet::Test;
use base 'DBIx::Class::ResultSet';
use List::Util qw/ none /;
use Digest::MD5 qw/md5_hex/;
use strict;
use warnings;

# ATTENTION: doesnt scale with large number of tags
# searching the DB for tests is a weak spot for DoS attacks.
# The more tags, the more expensive is the query
sub filtered_by_tag_ids {
    my ( $self, $tag_ids ) = @_;

    return $self unless defined $tag_ids;

    my $num_tags = scalar @$tag_ids;
    return $self unless $num_tags;

    return $self->search_rs(
        {   map {
                      'test_tags'
                    . ( $_ ? '_' . ( $_ + 1 ) : q{} )
                    . '.tag_id' => $tag_ids->[$_]
            } ( 0 .. $num_tags-1 )
        },
        { join => [ ('test_tags') x $num_tags ] }
    )->as_subselect_rs;
}

sub filtered_by_tag_names {
    my ( $self, $tag_names ) = @_;
    my @tags = $self->result_source->schema->resultset('Tag')->search(
        {
            name => { -in => $tag_names },
        }
    );
    my @tag_ids = map { $_->id } @tags;
    return $self->filtered_by_tag_ids(\@tag_ids);
}

sub filter_untagged {
    my ( $self ) = @_;
    my $untagged_tests = $self->search_rs(
        undef,
        {
            join     => 'test_tags',
            distinct => 1,
            having   => \ 'count(test_tags.id) = 0'
        }
    );
    return $untagged_tests;
}

sub with_config_tag {
    my ($self) = @_;
    return $self->filtered_by_tag_names(['config']);
}

sub default_order {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        { order_by => { -asc => [ "$alias.name" ] } }
    );
}

# helper sub to put together a case insensitive
# search using literal SQL
sub _lc_search {
    my ( $col, $query ) = @_;
    return -and => [ \[ "LOWER($col) LIKE ?", $query ], ];
}

# search for query in all Comment steps
sub search_comment {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    return $self->search_rs(
        {   'steps.type'       => 'Comment',
            _lc_search('steps.parameters', '%' . lc($query) . '%')
        },
        { join => 'steps', }
    );
}
sub search_name {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    my $alias = $self->current_source_alias;
    return $self->search_rs(
        {
            _lc_search("$alias.name", '%' . lc($query) . '%')
        },
    );
}

sub with_tags {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        {
            prefetch => { test_tags => 'tag' },
            order_by => [
                { -asc => [ "$alias.name" ] },
                'tag.name',
            ]
        }
    );
}

1;
