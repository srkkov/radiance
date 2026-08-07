module radiance::integer <Unsigned>;

<*
 Performs logical left shift by a saturated shift amount.

 @require shift >= 0
*>
macro Unsigned saturated_shl(Unsigned x, int shift)
{
	return x << min(shift, KM1);
}

<*
 Performs logical right shift by a saturated shift amount.

 @require shift >= 0
*>
macro Unsigned saturated_shr(Unsigned x, int shift)
{
	return x >> min(shift, KM1);
}

<*
 Performs logical left shift by a truncated shift amount.

 @require shift >= 0
*>
macro Unsigned truncated_shl(Unsigned x, int shift)
{
	return x << (shift & KM1);
}

<*
 Performs logical right shift by a truncated shift amount.

 @require shift >= 0
*>
macro Unsigned truncated_shr(Unsigned x, int shift)
{
	return x >> (shift & KM1);
}


