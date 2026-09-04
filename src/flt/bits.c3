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
