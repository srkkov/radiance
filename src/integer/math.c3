module radiance::integer;

macro is_even(x) => _is_even{$Typeof(x)}(x);
macro is_odd(x) => _is_odd{$Typeof(x)}(x);

macro is_pow2(x) => _is_pow2{$Typeof(x)}(x);
macro is_mersenne(x) => _is_mersenne{$Typeof(x)}(x);

module radiance::integer <Integer>;

fn bool _is_even(Integer x) @inline
{
	return !(x & 1);
}

fn bool _is_odd(Integer x) @inline
{
	return !!(x & 1);
}

fn bool _is_pow2(Integer x) @inline
{
	$if SIGNED:
		if (x <= 0) return false;
	$endif
	return x & (x - 1) == 0;
}

fn bool _is_mersenne(Integer x) @inline
{
	$if SIGNED:
		if (x < 0) return false;
	$endif
	return (x + 1) & x == 0;
}
