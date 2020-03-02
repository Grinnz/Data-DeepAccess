package Data::DeepAccess;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';
use Sentinel 'sentinel';

our $VERSION = '0.001';

our @EXPORT_OK = qw(deep_exists deep_get deep_set);

sub deep_exists {
  my ($structure, @keys) = @_;
  return !!1 unless @keys;
  foreach my $key_i (0..$#keys) {
    return !!0 unless defined $structure;
    my $type = blessed $structure ? 'method' : lc ref $structure;
    my $key = $keys[$key_i];
    my $lvalue;
    if (ref $key eq 'HASH') {
      if (exists $key->{key}) {
        ($type, $key) = ('hash', $key->{key});
      } elsif (exists $key->{index}) {
        ($type, $key) = ('array', $key->{index});
      } elsif (exists $key->{method}) {
        ($type, $key) = ('method', $key->{method});
      } elsif (exists $key->{lvalue}) {
        ($type, $key, $lvalue) = ('lvalue', $key->{method}, 1);
      } else {
        croak q{Traversal key hashref must contain 'key', 'index', 'method', or 'lvalue'};
      }
    }
    if ($type eq 'hash') {
      return !!0 unless exists $structure->{$key};
      return !!1 if $key_i == $#keys;
      $structure = $structure->{$key};
    } elsif ($type eq 'array') {
      return !!0 unless exists $structure->[$key];
      return !!1 if $key_i == $#keys;
      $structure = $structure->[$key];
    } elsif ($type eq 'method') {
      return !!0 unless my $sub = $structure->can($key);
      return !!1 if $key_i == $#keys;
      $structure = $sub->();
    } else {
      croak qq{Cannot traverse '@{[ref $structure]}'};
    }
  }
}

1;

=head1 NAME

Data::DeepAccess - Access or set data in deep structures

=head1 SYNOPSIS

  use Data::DeepAccess qw(deep_exists deep_get deep_set);

  my %things;
  deep_set(\%things, qw(foo bar), 42);
  say $things{foo}{bar}; # 42

  $things{foo}{baz} = ['a'..'z'];
  say deep_get(\%things, qw(foo baz 5)); # f

  deep_get(\%things, qw(foo baz 26)) = 'AA';
  say $things{foo}{baz}[-1]; # AA

=head1 DESCRIPTION

Provides the functions L</"deep_get"> and L</"deep_set"> that traverse nested
data structures to retrieve or set the value located by a list of keys.

When traversing, keys are applied according to the type of referenced data
structure. A hash will be traversed by hash key, an array by array index, and
an object by method call (scalar context). If the data structure is not
defined, it will be traversed as a hash by default (but not vivified unless in
a set operation).

You can override how a key is applied, and thus what type of structure is
vivified if necessary, by passing the key in a hashref as the value of C<key>
(hash) or C<index> (array).

  deep_set(my $structure, 'foo', 42); # {foo => 42}
  deep_set(my $structure, {index => 1}, 42); # [undef, 42]
  deep_set($object, {key => 'foo'}, 42); # sets $object->{foo} directly

For the rare case it's needed, you can also use one of the keys C<method> or
C<lvalue>.

  deep_set($object, {method => 'foo'}, 42); # $object->foo(42)
  deep_set($object, {lvalue => 'foo'}, 42); # $object->foo = 42

Attempting to traverse intermediate structures that are defined and not a
reference to a hash, array, or object will result in an exception.

If an object method call is the last key in a set operation or the next
structure must be vivified, the method will be called passing the new value as
an argument. Attempting to vivify an object method in a set operation will
result in an exception.

=head1 FUNCTIONS

All functions are exported individually.

=head2 deep_exists

  my $bool = deep_exists($structure, @keys);

Returns a true value if the value exists in the referenced structure located by
the given keys. No intermediate structures will be altered or vivified; a
missing structure will result in a false return value.

Array indexes are tested for existence with L<perlfunc/exists>, like hash
keys, which may have surprising results in sparse arrays. Avoid this situation.

Object methods are tested for existence with C<< $object->can($method) >>.

=head2 deep_get

  my $value  = deep_get($structure, @keys);
  $new_value = deep_get($structure, @keys) = $new_value;

Retrieves the value from the referenced structure located by the given keys. No
intermediate structures will be altered or vivified; a missing structure will
result in C<undef>.

If used as an lvalue, acts like L</"deep_set">.

=head2 deep_set

  $new_value = deep_set($structure, @keys, $new_value);

Sets the value in the referenced structure located by the given keys. Missing
intermediate structures will be vivified to hashrefs by default.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Hash::DeepAccess>, L<Data::DPath>, L<Data::Deep>
