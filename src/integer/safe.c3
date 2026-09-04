module radiance::integer <Integer> @private;
import std::math;
/* overflow_add
   overflow_sub
   overflow_mul */

faultdef OUT_OF_RANGE, DIVISION_BY_ZERO;

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_abs(Integer x)
{
	$if SIGNED:
		if (x == Integer::min) return OUT_OF_RANGE~;
		return _abs(x);
	$else
		return x;
	$endif
}

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_neg(Integer x) @if(SIGNED)
{
	if (x == Integer::min) return OUT_OF_RANGE~;
	return -x;
}

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_add(Integer x, Integer y)
{
	Integer r;
	if (std::math::overflow_add(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_sub(Integer x, Integer y)
{
	Integer r;
	if (std::math::overflow_sub(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @return? OUT_OF_RANGE
*>
fn Integer? _try_mul(Integer x, Integer y)
{
	Integer r;
	if (std::math::overflow_mul(x, y, &r)) return OUT_OF_RANGE~;
	return r;
}

<*
 @return? DIVISION_BY_ZERO, OUT_OF_RANGE
*>
fn Integer? _try_div(Integer x, Integer y)
{
	if (!y) return DIVISION_BY_ZERO~;
	$if SIGNED:
		if (x == Integer::min && y == -1) return OUT_OF_RANGE~;
	$endif
	return x / y;
}

module radiance::integer;

macro try_abs(x) => _try_abs{$Typeof(x)}(x);
macro try_neg(x) => _try_neg{$Typeof(x)}(x);
macro try_add(x) => _try_add{$Typeof(x)}(x);
macro try_sub(x) => _try_sub{$Typeof(x)}(x);
macro try_mul(x) => _try_mul{$Typeof(x)}(x);

macro exact_abs(x) => _try_abs{$Typeof(x)}(x)!!;
macro exact_neg(x) => _try_neg{$Typeof(x)}(x)!!;
macro exact_add(x) => _try_add{$Typeof(x)}(x)!!;
macro exact_sub(x) => _try_sub{$Typeof(x)}(x)!!;
macro exact_mul(x) => _try_mul{$Typeof(x)}(x)!!;







