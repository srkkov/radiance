module radiance::integer <Integer> @private;

macro bool @_is_even(Integer $x)
{
	return !($x & 1);
}

macro bool @_is_odd(Integer $x)
{
	return !!($x & 1);
}

macro Integer @_max(Integer $x, Integer $y)
{
	return $x > $y ? $x : $y;
}

macro Integer @_min(Integer $x, Integer $y)
{
	return $x < $y ? $x : $y;
}

<*
 @require $x > 0
 @ensure return >= 0, return < K
*>
macro int @_log2(Integer $x)
{
	int $r;
	$for ;($x >>= 1);:
		$r++;
	$endfor
	return $r;
}

module radiance::integer;

macro bool @is_even($x) @const => @_is_even{$Typeof($x)}($x);
macro bool @is_odd($x) @const => @_is_odd{$Typeof($x)}($x);

macro @max($x, $y) @const => @_max{$Typeof($x)}($x, $y);
macro @min($x, $y) @const => @_min{$Typeof($x)}($x, $y);

macro int @log2($x, $y) @const => @_log2{$Typeof($x)}($x);

