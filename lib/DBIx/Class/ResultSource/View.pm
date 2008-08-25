package DBIx::Class::ResultSource::View;

use strict;
use warnings;

use DBIx::Class::ResultSet;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ResultSource/);

=head1 NAME

DBIx::Class::ResultSource::Table - Table object

=head1 SYNOPSIS

=head1 DESCRIPTION

Table object that inherits from L<DBIx::Class::ResultSource>

=head1 METHODS

=head2 from

Returns the FROM entry for the table (i.e. the view name)

=cut

sub from { shift->name; }

1;

=head1 AUTHORS

Matt S. Trout <mst@shadowcatsystems.co.uk>

With Contributions from:

Guillermo Roditi E<lt>groditi@cpan.orgE<gt>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

