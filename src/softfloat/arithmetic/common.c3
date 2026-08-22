module radiance::flt::binary <WIDTH, PRECISION> @private;
import radiance::integer @public, radiance::integer::bit @public;

<*
 Extracts the biased exponent field.

 @require is_regular(abs_x) && !_sign(abs_x)
 @ensure return <= integer::max_unsigned_bits(EXP_BITS) - 1
*>
macro FInt _biased_exponent(FInt abs_x)
{
	return abs_x >> FRAC_BITS;
}
// Notes:
//
//   EXP_MIN + EXP_MAX = 1
//
//   exponent = biased_exponent - EXP_MAX + is_subnormal
//            = biased_exponent - EXP_MAX + 1 - is_normal
//            = biased_exponent + EXP_MIN - is_normal
//
//   biased_exponent = exponent - EXP_MIN + is_normal


<*
 Returns true if abs_x is a normal number, false otherwise.

 @require is_regular(abs_x)
*>
macro bool _normal_bit(FInt abs_x)
{
	return abs_x >= MIN_NORMAL;
}

<*
 Packs the significand and exponent into an ieee754-interchange encoding and applies rounding.

 @param u : "Result truncated significand, may be subnormalized."
 @param d : "Modified result exponent d = er - EXP_MIN = br - nr."
 @param rounding : "Equal to 1 if we should compute the successor of u."

 @require u <= integer::max_unsigned_bits(PRECISION)
 @require d <= integer::max_unsigned_bits(EXP_BITS) - 1
 @require rounding <= 1

 @ensure !_sign(return), !is_nan(return)
*>
fn FInt _round_pack(FInt u, FInt d, FInt rounding) @inline
{
	// Parameters:
	//  - u must equal the result truncated significand, correctly subnormalized if needed.
	//  - rounding = 1 indicates that we should encode the successor of u instead.
	//  - The value of d is equal to result_exponent - EXP_MIN, which is explained below.

	// Let br and er be the result's biased and unbiased exponent respectively. Let nr be the
	// is_normal bit of the result and let R be the integer encoding of the resulting floating point 
	// number. Recall that
	//
	//   br = er - EXP_MIN + nr
	//
	// We are to encode with an implicit leading bit, and only store the fractional component of u.
	// But we can avoid explictly removing the leading bit. First initialize the exponent field of R 
	// to d = er - EXP_MIN,
	// 
	//   R = d << FRAC_BITS = 0 dddddddd 00000000000000000000000
	//
	// then add the raw integer value of the significand to R. This will simultaneously set the 
	// fraction field and increment the exponent field by the leading bit, which is equal to nr 
	// just as in the above equation for br.
	//
	//  R     = 0 dddddddd 00000000000000000000000
	//  u     = 0 0000000n fffffffffffffffffffffff
	//
	//  R + u = 0 eeeeeeee fffffffffffffffffffffff
	//
	// If the result is subnormal, then er = EXP_MIN, thus d = 0. The significand will be less than
	// than p-bits wide, thus d will not be incremented, which correctly encodes subnormal numbers.

	// Rounding is then applied simply by adding the rounding bit to R. If the rounding bit
	// is 1, then the successor is correctly computed. Even in the case where the fraction field
	// overflows, the exponent field is incrementing correctly. Also note that if R = MAX_NORMAL,
	// adding 1 correctly gives the encoding for INF again via overflow.

	return ((d << FRAC_BITS) + u) + rounding;
}

<*
 Packs the significand and exponent into an ieee754-interchange encoding, same as `_round_pack`
 but without applying rounding
*>
fn FInt _pack(FInt u, FInt d) @inline
{
	return (d << FRAC_BITS) + u;
}

<*
 Normalizes the significand without needed to extract the exponent. As a by-product, returns a 
 value that can be used to calculate the result exponent

 @param        abs_x
 @param[&out]  out_mlz_x : "Modified number of significand leading zeros, mlz_x = lz_x + EXP_BITS."
 @return                   "Normalized significand, justified to the left of the word."

 @require[abs_x] is_regular(abs_x) && !_sign(abs_x)
 @ensure *out_mlz_x <= K
*>
fn FInt _normalize(int* out_mlz_x, FInt abs_x) @inline
{
	// Two cases:
	//  1. abs_x is normal, the exponent field is non-zero, therefore lzcnt(abs_x) <= EXP_BITS
	//     and mlz = EXP_BITS. Shifting left by EXP_BITS leaves 1 bit after the fraction, and
	//     we ensure that bit is set (the implicit bit).
	//     
	//  2. abs_x is subnormal, the exponent field is non-zero, thus lzcnt(abs_x) > EXP_BITS
	//     and we directly shift the leading one of the fraction to the left.
	//
	// The value mlz_x can be used to calculate the number of significand leading zeros lz_x.
	//
	//   lz_x = mlz_x - EXP_BITS
	//
	// When abs_x is normal, mlz_x = EXP_BITS so lz_x = 0 as expected. When abs_x is subnormal,
	// mlz_x = EXP_BITS + 1 + <number of leading zero fraction bits>. Notice that the +1 (from
	// the sign field) accounts for the implicit bit being zero.


	int mlz_x = integer::max(bit::lzcnt(abs_x), EXP_BITS);
	*out_mlz_x = mlz_x;
	return (abs_x << mlz_x) | SIGN_MASK;
}

<*
 Splits the unbounded exponent if it is smaller than EXP_MIN.

 @param[&out]  out_lz  : "The number of leading zeros that should be in the significand of the result."
 @param        em      : "Modified unbounded exponent em = e - EXP_MIN."
 @return                 "Modified result exponent d = er - EXP_MIN = br - nr."

 @ensure *out_lz >= 0
*>
fn FInt _split_exponent(int* out_lz, int em)
{
	*out_lz = integer::max0(-em);
	return (FInt)integer::max0(em);
}

<*
 Returns true if the result exponent is out of systems exponent range.
*>
fn bool _exponent_overflow(FInt d)
{
	// Definite overflow if e > EXP_MAX. Since er = e when e >= EXP_MIN, we have
	// d = er - EXP_MIN > EXP_MAX - EXP_MIN.

	return d >= 2*EXP_MAX;
}

macro FInt _reduce_or(FInt high_r, int bits = ...)
{
	$if $defined(bits):
		return (FInt)(high_r << (K - bits) != 0);
	$else
		return (FInt)(high_r != 0);
	$endif
}





















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
	FInt arg;
	$for sz $i; $i < $vaarg.len; $i++:
		arg = $vaarg[$i];
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

