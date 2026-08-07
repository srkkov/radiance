<*
 @require is_int(Integer)
*>
module radiance::integer <Integer>;

struct QuoRem
{
	Integer quotient, remainder;
}

<*
 @require !SIGNED ||| !(dividend == Integer::min && divisor == -1) : "Result is not representable in integer range"
 @require divisor != 0
*>
fn QuoRem divrem(Integer dividend, Integer divisor) @inline
{
	return {
		.quotient  = dividend / divisor, 
		.remainder = dividend % divisor,
	};
}

alias divrem_trunc = divrem;

<*
 @require !SIGNED ||| !(dividend == Integer::min && divisor == -1) : "Result is not representable in integer range"
 @require divisor != 0
*>
fn QuoRem divrem_floor(Integer dividend, Integer divisor)
{
	QuoRem result = divrem(dividend, divisor);

	$if SIGNED:
		if (result.remainder && !same_signs(result.remainder, divisor))
		{
			result = _adjust(result, divisor, -1);
		} 
	$endif

	return result;
}

<*
 @require !SIGNED ||| !(dividend == Integer::min && divisor == -1) : "Result is not representable in integer range"
 @require divisor != 0
*>
fn QuoRem divrem_ceil(Integer dividend, Integer divisor)
{
	QuoRem result = divrem(dividend, divisor);

	if (result.remainder)
	{
		$if SIGNED:
			if (same_signs(result.remainder, divisor))
			{
				result = _adjust(result, divisor, +1);
			}
		$else
			result = _adjust(result, divisor, +1);
		$endif
	}

	return result;
}

<*
 @require !SIGNED ||| !(dividend == Integer::min && divisor == -1) : "Result is not representable in integer range"
 @require divisor != 0
 @ensure !SIGNED ||| return.remainder >= 0
*>
fn QuoRem divmod(Integer dividend, Integer divisor)
{
	QuoRem result = divrem(dividend, divisor);

	$if SIGNED:
		if (result.remainder < 0)
		{
			result = _adjust(result, divisor, divisor > 0 ? -1 : 1);
		}
	$endif

	return result;
}

macro QuoRem _adjust(QuoRem result, Integer divisor, int dq) @private
{
	result.quotient += (Integer)(dq);
	result.remainder += (Integer)(-dq) * divisor;
	return result;
}

macro same_signs(x, y) @local
{
	return (x < 0) == (y < 0);
}

















