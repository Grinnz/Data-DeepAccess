use strict;
use warnings;
use Data::DeepAccess qw(deep_exists deep_get);
use Test2::V0;

{
  package My::Test::Class;
  sub new { bless {foo => 42}, shift }
  sub foo { @_ > 1 ? do {$_[0]{foo} = $_[1]; $_[0]} : $_[0]{foo} }
}

my $data = {a => [undef,{b => 42, 0 => sub {}}], b => My::Test::Class->new, c => undef};

ok deep_exists($data), 'root structure exists';
ref_is deep_get($data), $data, 'get root structure';
ok deep_exists($data, 'a'), 'hash key exists';
ref_is deep_get($data, 'a'), $data->{a}, 'get hash key';
ok deep_exists($data, 'b'), 'hash key exists';
ref_is deep_get($data, 'b'), $data->{b}, 'get hash key';
ok deep_exists($data, 'c'), 'hash key exists';
is deep_get($data, 'c'), $data->{c}, 'get undef hash key';
ok !deep_exists($data, 'c', 'a'), 'undef has no elements';
is deep_get($data, 'c', 'a'), undef, 'undef has no elements';
ok !deep_exists($data, 'd'), 'hash key does not exist';
is deep_get($data, 'd'), undef, 'get nonexistent hash key';
ok !deep_exists($data, 'd', 'd'), 'hash key does not exist';
is deep_get($data, 'd', 'd'), undef, 'get nonexistent hash key';
ok !deep_exists($data, 0), 'hash key does not exist';
is deep_get($data, 0), undef, 'get nonexistent hash key';
ok deep_exists($data, 'a', 0), 'array element exists';
is deep_get($data, 'a', 0), undef, 'get undef array element';
ok deep_exists($data, 'a', 1), 'array element exists';
ref_is deep_get($data, 'a', 1), $data->{a}[1], 'get array element';
ok !deep_exists($data, 'a', 2), 'array element does not exist';
is deep_get($data, 'a', 2), undef, 'get nonexistent array element';
ok !deep_exists($data, 'a', 0, 0), 'undef has no elements';
is deep_get($data, 'a', 0, 0), undef, 'undef has no elements';
ok deep_exists($data, 'a', 1, 'b'), 'hash key exists';
is deep_get($data, 'a', 1, 'b'), $data->{a}[1]{b}, 'get hash key';
like dies { deep_exists($data, 'a', 1, 'b', 'c') }, qr/Cannot traverse/i, 'cannot traverse defined scalar';
like dies { deep_get($data, 'a', 1, 'b', 'c') }, qr/Cannot traverse/i, 'cannot traverse defined scalar';
ok deep_exists($data, 'a', 1, 0), 'hash key exists';
ref_is deep_get($data, 'a', 1, 0), $data->{a}[1]{0}, 'get hash key';
like dies { deep_exists($data, 'a', 1, 0, undef) }, qr/Cannot traverse/i, 'cannot traverse coderef';
like dies { deep_get($data, 'a', 1, 0, undef) }, qr/Cannot traverse/i, 'cannot traverse coderef';
ok deep_exists($data, 'b', 'foo'), 'method exists';
is deep_get($data, 'b', 'foo'), $data->{b}->foo, 'get method value';
ok !deep_exists($data, 'b', 'bar'), 'method does not exist';
is deep_get($data, 'b', 'bar'), undef, 'method does not exist';
like dies { deep_exists($data, 'b', 'foo', 'bar') }, qr/Cannot traverse/i, 'cannot traverse defined scalar';
like dies { deep_get($data, 'b', 'foo', 'bar') }, qr/Cannot traverse/i, 'cannot traverse defined scalar';

is $data, hash {
  field a => array {
    item undef;
    item hash {field b => 42; field 0 => D; end};
    end;
  };
  field b => object {
    prop blessed => 'My::Test::Class';
    call foo => 42;
  };
  field c => undef;
  end;
}, 'data structure unchanged';

done_testing;
