module radiance::flt::binary <WIDTH, PRECISION> @private;
import radiance::integer @public, radiance::integer::bit @public;

<*
 Extracts the *biased exponent* field of the absolute value of an ieee754 binary 
 floating point bitstring.

 Example for binary32:

	abs_x  = 0 eeeeeeee fffffffffffffffffffffff
	return = 0 00000000 000000000000000eeeeeeee

 @require is_regular(abs_x)
 @ensure return < integer::max_unsigned_bits(EXP_BITS)
*>
macro FInt _biased_exponent(FInt abs_x)
{
	return abs_x >> FRAC_BITS;
}

<*
 Returns true if the given absolute value of an ieee754 binary 
 floating point is a normal number.

 @require is_regular(abs_x)
*>
macro bool _normal_bit(FInt abs_x)
{
	return abs_x >= MIN_NORMAL;
}

<*
 Packs all components of the resulting floating point number, excluding the sign,
 and simultaneously applies rounding.

 --- Explanation ---

 Let `r` be the result floating point number of some scalar-valued operation.
 Let `e` be the exponent of the `r` in the unbounded domain.
 Let `u` be the truncated significand of `r`, and `f` be the truncated fraction of `r`.

 Let `d` be the biased value of `e` in the current floating point format.
 At this point overflow before rounding as been taken care of.

 --- Rounding ---

 Before rounding, our result looks like this:

	0 dddddddd fffffffffffffffffffffff

 We can see that rounding can be applied simply by just adding the rounding bit to the result 
 as a `k-1` bit integer. An overflow of the fraction field will increment the exponent field 
 automatically, and in the case of *overflow after rounding*, where `e = EXP_MAX` and 
 `f = 1 << FRAC_BITS - 1`, it will automatically overflow into the representation of `INF`.

	  0 11111110 11111111111111111111111    (largest normal)
	+                                  1
	------------------------------------
	= 0 11111111 00000000000000000000000    (infinity)

 It's also the case that the largest subnormal number will automatically transition
 to the smallest normal number.

	  0 00000000 11111111111111111111111    (largest subnormal)
	+                                  1
	------------------------------------
	= 0 00000001 00000000000000000000000    (smallest normal)

 --- Packing ---

 Before rounding, we must pack the absolute value of the result:

 	0 dddddddd fffffffffffffffffffffff 

 We must calulate the truncated fraction `f` of the result before applying rounding,
 but we commonly have the truncated significand `u` after the core computation, which 
 just has the hidden leading 1, `u = 1.ff...f`.

 Instead of removing the hidden bit, it's more efficient to calculate `d - 1`, and pack by 
 computing `(d - 1) << FRAC_BITS + u`. In the case of normal numbers the hidden 1 in `u` will
 just increment the `d - 1` field back to the value of `d`. In the case of subnormal numbers,
 we've clamped `d = 0` and `u` will not contain the hidden leading 1, thus `d` is unchanged.

 TODO: Write and point to the description of how we calculate `d - 1`.

 --- End ---

 @require u <= integer::max_unsigned_bits(PRECISION)
 @require dm1 <= integer::max_unsigned_bits(EXP_BITS) - 1
 @require rounding <= 1
*>
macro FInt _round_pack(FInt u, FInt dm1, FInt rounding)
{
	return ((dm1 << FRAC_BITS) + u) + rounding;
}


macro FInt _reduce_or(FInt self, int width = ...)
{
	return $defined(width) ???
		bit::_trunc_reduce_or{FInt}(self, width) : bit::_reduce_or{FInt}(self);
}

alias _max = integer::max;
alias _min = integer::min;
alias _mul = integer::_umul{FInt};
alias _mulhi = integer::_umulhi{FInt};
alias _lzcnt = bit::_count_leading_zeros{FInt};


// =======================
// --- Input Filtering ---
// =======================

<*
 At least one |xs[i]| < min or |xs[i]| > max .
 @require min > 0, max < INF
*>
macro bool _operands_not_within(FInt min, FInt max, ...)
{
	FInt[$vaarg.len] args;
	$for sz $i; $i < $vaarg.len; $i++:
		FInt arg = $vaarg[$i];
		assert(arg & SIGN_MASK == 0);
		args[$i] = arg - min;
	$endfor
	return integer::max(...args) > max - min;
}


macro bool _special_operands(...)
{
	return _operands_not_within(MIN_SUBNORMAL, MAX_NORMAL, ...$vaarg);
}

macro bool _special_or_subnormal_operands(...)
{
	return _operands_not_within(MIN_NORMAL, MAX_NORMAL, ...$vaarg);
}


// ========================
// --- Rounding Helpers ---
// ========================


/* Meaning of round bit and sticky bit.
 
 r := exact result
 t := truncated result
 h := t + 2^-p  (halfway between t and t+)
 
 round | sticky || relation
 --------------------------
     0 | 0      ||  r = t
     0 | 1      || t < r < h
     1 | 0      ||  r = h
     1 | 1      ||  r > h
*/

/* Note:
 Rounding *towards zero* is the same as taking the truncated result.
 Rounding *away from zero* is the same as taking the successor of the truncated result.
*/

<*
 Computes rounding for "round to nearest, ties to even" rounding mode. 

 round | sticky || rounding
 --------------------------
     0 | 0      ||    0
     0 | 1      ||    0
     1 | 0      ||    lsb
     1 | 1      ||    1
 
 @require sticky <= 1, round <= 1
 @ensure return <= 1
*>
macro FInt _round_nearest_even(FInt round, FInt sticky, FInt lsb)
{
	return round & (lsb | sticky);
}

<*
 Computes rounding for "round to nearest, ties to odd" rounding mode. 

 round | sticky || rounding
 --------------------------
     0 | 0      ||    0
     0 | 1      ||    0
     1 | 0      ||   !lsb
     1 | 1      ||    1
 
 @require sticky <= 1, round <= 1
 @ensure return <= 1
*>
macro FInt _round_nearest_odd(FInt round, FInt sticky, FInt lsb)
{
	return round & (~lsb | sticky);
}

<*
 Computes rounding for "round towards positive infinity" rounding mode. 
 
 round | sticky || rounding
 --------------------------
 	0 | 0       ||    0
 	0 | 1       ||   !sign
 	1 | 0       ||   !sign
 	1 | 1       ||   !sign
 
 @require sticky <= 1, round <= 1, sign == sign & SIGN_MASK
 @ensure return <= 1
*>
macro FInt _round_up(FInt round, FInt sticky, FInt sign)
{
	return ~(sign >> KM1) & (round | sticky);
}

<*
 Computes rounding for "round towards negative infinity" rounding mode. 
 
 round | sticky || rounding
 --------------------------
 	0 | 0       ||    0
 	0 | 1       ||    sign
 	1 | 0       ||    sign  
 	1 | 1       ||    sign
 
 @require sticky <= 1, round <= 1, sign == sign & SIGN_MASK
 @ensure return <= 1
*>
macro FInt _round_down(FInt round, FInt sticky, FInt sign)
{
	return (sign >> KM1) & (round | sticky);
}

