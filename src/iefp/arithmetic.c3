<*
 Two Generic Types, `FInt` and `SigInt`.

 Type `FInt` is the unsigned integer no smaller than the floating point encoding size.

 Type `SigInt` is the unsigned integer used to in significand computations. Some functions require
 varying minimum sizes for `SigInt`.
*>
module radiance::iefp::binary;
import radiance::integer;

/* Basics and Notation

 Important consequences of the IEEE754 encoding:

   EXP_MIN + EXP_MAX = 1,    BIAS = EXP_MAX

 We have

   exponent = biased_exponent - BIAS = biased_exponent - EXP_MAX

 The exponent field encoding for an exponent value of EXP_MIN is EXP_MIN - BIAS = 1.
 When a floating point number is subnormal, the exponent field encoding is 0, but its exponent
 is EXP_MIN. Thus we must adjust for this when decoding the biased exponent.

   exponent = biased_exponent - EXP_MAX + is_subnormal
            = biased_exponent - EXP_MAX + 1 - is_normal
            = biased_exponent + EXP_MIN - is_normal

   biased_exponent = exponent - EXP_MIN + is_normal

 Notation:

 e  := unbounded immediate result exponent, associated to a possibly un-normalized significand.
       This value is more of a theoretical aid.
 ef := unbounded immediate result exponent after normalization, but not subnormalization.
 e* := exponent of a floating point number assuming a normalized and subnormalized significand.
       This value is more of a theoretical aid, we always work with the biased exponent.
 w* := raw, unadjusted, biased exponent of a floating point number.
 n* := "is normal" 1-bit value of a floating point number, 1 if normal, 0 if subnormal.

 For a floating point number x, ex = wx + EXP_MIN - nx and wx = ex - EXP_MIN + nx just as shown above.

 d  := modified result exponent, d = wr - nr = er - EXP_MIN.
 s* := sign of the floating point number.
 u  := normalized and subnormalized result truncated significand.

 lz_* := The number of significand leading zeros of a floating point number assuming a normalized and
         subnormalized significand.

 Exponent Computation:

 lz_r is the number of leading zeros the result significand should have.

   lz_r = max(EXP_MIN - e', 0)

 Essentially counting how far er "overshoots" EXP_MIN.
 To compute er, we clamp e' to EXP_MIN.

   er = max(e', EXP_MIN)

 The computation of d is similar to that of lz_r.

   d  = er - EXP_MIN = max(e' - EXP_MIN, 0)

 See function `_split_exponent`.
*/


<*
 @require px + wx <= WIDTH
*>
macro FInt add_2a(int pr, int wr,
                  FInt x, int px, int wx,
                  FInt y, int py, int wy,
                  bool sign,
                  FltRoundingMode rounding_mode,
                  bool zero_subnormal_inputs, bool zero_subnormal_outputs)
{
	FInt  sr, sx, sy;
	FInt  abs_x, abs_y;
	FInt  max_abs, min_abs;
	bool  s;

	abs_x = _abs(px, qx, x);
	abs_y = _abs(py, qy, y);

	sx = _isolate_sign(px, gx, x);
	sy = _isolate_sign(py, gy, y);

	s = (sx != sy) != sign;

	if (abs_x == abs_y)
	{
		sr = s ? 0 : sx;
	}
	else
	{
		// complete garbage this can 100% be cleaned up
		sr = ((FInt)(s && abs_x < abs_y) << KM1) ^ sx;
	}

	if (/*special operands*/)

}



<*
 Computes ∘(x ± y), addition or subtraction if sign is false or true.
*>
fn FInt add2(FInt x, FInt y, bool sign)
{
	FInt  sr, sx, sy;
	FInt  abs_x, abs_y;
	FInt  max_abs, min_abs;
	bool  s;

	abs_x = _abs(x);
	abs_y = _abs(y);

	sx = x & SIGN_MASK;
	sy = y & SIGN_MASK;

	// effective operation, 0 = addition, 1 = subtraction
	s = (sx != sy) != sign;


	if (abs_x == abs_y)
	{
		sr = s ? 0 : sx;
	}
	else
	{
		sr = ((FInt)(s && abs_x < abs_y) << KM1) ^ sx;
	}

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = integer::max(abs_x, abs_y);

		// Either at least one operand is NaN or |x| and |y| are infinities with opposite signs.
		if (max_abs > INF || (s && abs_x == INF && abs_y == INF))
		{
			// we propogate the NaN with the larger payload
			// TODO: Customizable NaN progapation rule
			return QNAN | max_abs;
		}

		// |x| and |y| are infinities with the same sign, or they are zeros
		// zero or infinity with respective sign.
		return sr | max_abs;
	}

	// x = -y not covered by general case
	// only for RN
	if (abs_x == abs_y && s) return 0; // +0

	integer::@maxmin(abs_x, abs_y);

	return _add2(abs_x, abs_y, s, sr);
}

<*
 Computes ∘(|x| ± |y|). Does subtraction if `s` is true, addition otherwise.

 @require !_sign(abs_x), !_sign(abs_y)
 @require abs_x > abs_y || (!s && abs_x == abs_y)
 @require sr & SIGN_MASK == sr
*>
fn FInt _add_2(int p, int w
               FInt abs_x, int px, int wx,
               FInt abs_y, int py, int wy,
               bool s, FInt sr)
{
	FInt  mx, my;
	FInt  gx, gy;
	bool  nx, ny;
	FInt  high_r, abs_r, u, d;
	FInt  rounding, round, sticky;
	int   e_diff, t, n, c, lz_r;

	gx = _biased_exponent(px, wx, abs_x);
	gy = _biased_exponent(py, wy, abs_y);

	nx = _normal_bit(px, wx, abs_x);
	ny = _normal_bit(px, wy, abs_y);

	// used later
	t = (int)wx - (int)nx;

	// e_diff = ex - ey
	e_diff = t - ((int)wy - (int)ny);

	// Construct and prepare the significand for addition.
	//   0 ··· m[0] . m[1] m[2] ··· m[p-1] 0 0 0
	// We do not normalize subnormal inputs, since the possibility of cancellation
	// means we have to normalize the result anyway.

	fn SigInt make_sig(int px, bool nx, FInt abs_x)
	{
		return (((SigInt)nx << (px - 1)) | (SigInt)bit::isolate_low(abs_x, px - 1)) << 3;
	}

	mx = make_sig(px, nx, abs_x);
	my = make_sig(py, ny, abs_y);

	high_r = _sig_add_2(p, mx, my, e_diff, s);

	n = bit::lzcnt(high_r);

	// Normalize
	high_r <<= n;
	n -= K - p - 3;

	// er - EXP_MIN = ex - n - EXP_MIN = wx - nx - n
	d = _split_exponent(w, &lz_r, t - n);

	if (_exponent_overflow(w, d))
	{
		return sr | _inf(p, w);
	}

	// Subnormalize
	high_r >>= lz_r;

	sticky = _reduce_or(high_r, K - p - 1);
	round = bit::test(high_r, K - p - 1);

	u = high_r >> (K - p);

	rounding = _get_rounding_RNE(round, sticky, u);

	abs_r = _round_pack(p, w, u, d, rounding);
	return sr | abs_r;
}


fn FInt mul2(FInt x, FInt y)
{
	FInt  abs_x, abs_y, max_abs, min_abs;
	FInt  sr;

	abs_x = _abs(x);
	abs_y = _abs(y);

	sr = (x ^ y) & SIGN_MASK;

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = integer::max(abs_x, abs_y);
		min_abs = integer::min(abs_x, abs_y);

		switch
		{
			// Either at least one operand is NaN, or one operand is zero and the other is inf
			case max_abs > INF || (min_abs == 0 && max_abs == INF):
				return QNAN | max_abs;

			// both operands are zero
			case max_abs != INF:
				return sr;

			// both operands are inf
			default:
				return sr | INF;
		}
	}
	return _mul2(abs_x, abs_y, sr);
}

fn FInt _mul_2(int p, w,
              int px, int wx, FInt abs_x,
			  int py, int wy, FInt abs_y,
			  FInt sr)
{
	FInt  mx, my;
	FInt  bx, by;
	bool  nx, ny;
	FInt  high_r, low_r, abs_r, u, d;
	FInt  rounding, round, sticky;
	int   mlz_x, mlz_y, em, c, lz_r;

	bx = _biased_exponent(px, qx, abs_x);
	by = _biased_eyponent(py, qy, abs_y);

	nx = _normal_bit(px, qx, abs_x);
	ny = _normal_bit(py, qy, abs_y);

	mx = _normalize(&mlz_x, abs_x);
	my = _normalize(&mlz_y, abs_y);

	high_r = _sig_mul_2(&low_r, mx, my);

	c = (int)bit::msb(high_r);

	// Exponent Computation
	//   em = e - EXP_MIN,     e = ex - lz_x + ey - lz_y + c
	//
	//   ex + ey = (bx - nx) + (by - ny) + 2*EXP_MIN
	//   lz_x + lx_y  = mlz_x + mlz_y - 2*EXP_BITS
	em = ((int)bx - (int)nx) + ((int)by - (int)ny) - (mlz_x + mlz_y) + (2*EXP_BITS + EXP_MIN) + c;

	d = _split_exponent(&lz_r, em);

	if (_exponent_overflow(w, d))
	{
		return sr | _inf(p, w);
	}

	// Normalize
	high_r <<= (int)!c;

	// Subnormalize, lz_r can be very large
	high_r >>= integer::min(lz_r, K - 1);

	// Rounding
	sticky = _reduce_or(high_r, K - p - 1) | _reduce_or(low_r);
	round = bit::test(high_r, K - p - 1);

	u = high_r >> (K - P);

	rounding = _round_nearest_even(round, sticky, u);

	abs_r = _round_pack(u, d, rounding);
	return sr | abs_r;
}




module radiance::flt::binary <SigInt>;
import radiance::integer;

const K = integer::bitsize(SigInt);

<*
 Aligns and computes the addition or subtraction of significands.
 We need leading bit of space for carry and 3 trailing bits of space for guard, round, and sticky.

 @require[p]        p > 0, p + 1 + 3 <= K

 @require[mx]      mx != 0
 @require[mx]      !bit::extract_high(mx, 1)
 @require[mx]      !bit::isolate_low(mx, K - p - 1)

 @require[my]      my != 0
 @require[my]      !bit::extract_high(my, 1)
 @require[my]      !bit::isolate_low(my, K - p - 1)

 @require          mx != my || !s

 @require[e_diff]  e_diff >= 0
*>
fn SigInt _sig_add_2(int p, SigInt mx, SigInt my, int e_diff, bool s)
{
	// Besides alignment, we are doing 2 things here.
	//  1. Doing only a (p+4)-bit addition/subtraction.
	//  2. Precomputing the sticky bit before the addition/subtraction is done.
	//
	// This is accomplished by computing the sticky of the low bits of my, and *merging it* with
	// the addition/subtraction. That is, this sticky bit is attached to the significand.
	//
	//   high_y = 0 ··· 0 my[0] my[1] ··· my[p+1-δ] OR( my[p+2-δ .. p+2] )
	//
	// First note that if the sticky is zero, then we just truncate my to p+3 bits.
	//
	// Addition:
	//  All low bits would be added to zeros, thus they have no impact on the high part of the sum.
	//  This also means we can directly compute the sticky bit before the addition, merging it has
	//  no effect.
	//
	// Subtraction:
	//  All discarded bits would be subtracted from zeros, thus if any of the discarded bits are 1,
	//  a barrow will propagate as just the same as an effective subtraction by 1.
	//  And then thats the actual sticky because IDK.

	SigInt high_y, sticky;

	// align
	high_y = my >> integer::min(e_diff, K - 1);

	switch
	{
		// no bits discarded
		case e_diff <= 3:
			sticky = 0;

		// all bits discarded, but since my is nonzero, sticky is 1
		case e_diff >= p + 3:
			sticky = 1;

		// some bits discarded, we directly compute the sticky of these discarded bits
		default:
			sticky = _reduce_or(my, e_diff);
	}

	// merge
	high_y |= sticky;

	return mx + (s ? -high_y : high_y);
}

<*
 Multiplies 2 normalized significands and returns the full product.

 @param[&out] low_r : "Low half of product."
 @return              "High half of product."
*>
fn SigInt _sig_mul_2(SigInt* low_r, int p, SigInt mx, SigInt my)
{
	// Computes (1,p-1) fixed point product, which results in a (2, 2*(p-1)) fixed point
	// result. Therefore the low word contains (L - 2*p) trailing zeros
	//
	//    c m[0] . m[1] ··· m[p-1] ··· m[L-2] : m[L-1] ··· m[2p-1] 0 ··· 0
	//
	// if L - 2*p >= L
	return integer::_umul{FInt}(low_r, mx, my);
}





	//  s | |x| ? |y| || sr
	// --------------------
	//  0 |     >     || sx
	//  0 |     <     || sx
	//  1 |     >     || sx
	//  1 |     <     || !sx

module radiance::iefp::binary <FInt>;
import radiance::integer;

<*
 Returns the sign bit of `x`.

 @require[x] bit::clear_low(x, p + w) == 0
*>
fn bool _sign(int p, int w, FInt x)
{
	return !!(x & sign_mask(p, w));
}

<*
 Extracts the biased exponent field.

 @require is_regular(abs_x) && !_sign(abs_x)
 @ensure return <= integer::max_unsigned_bits(EXP_BITS) - 1
*>
macro FInt _biased_exponent(int p, int w, FInt abs_x)
{
	return (abs_x >> (p - 1));
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
macro bool _normal_bit(int p, int w, FInt abs_x)
{
	return abs_x >= _min_normal(p, w);
}

<*
 Packs the significand and exponent into an encoding and applies rounding.

 @param p : "precision"
 @param q : "exponent bits"

 @param u : "result truncated significand, may be subnormalized"
 @param d : "modified result exponent: d = er - EXP_MIN = wr - nr"
 @param rounding : "equal to 1 if we should compute the successor of u."

 @require[p] p > 0, p < 9999
 @require[u] u != 0, integer::isolate_high(u, K - p) != 0

 @require u <= integer::max_unsigned_bits(PRECISION)
 @require d <= integer::max_unsigned_bits(EXP_BITS) - 1
 @require rounding <= 1

 @ensure !_sign(return), !is_nan(return)
*>
fn FInt _round_pack(int p, int q, FInt u, FInt d, FInt rounding) @inline
{
	/* Notes:
	 Can we ever return 0?
	*/

	 // Recall that wr = er - EXP_MIN + nr and d = wr - nr

	return ((d << (p - 1)) + u) + rounding;
}

<*
 Same as `_round_pack` but without applying rounding.


 @ensure !_sign(return), !is_nan(return)
*>
fn FInt _pack(int p, int q, FInt u, FInt d) @inline
{
	return (d << p) + u;
}

<*
 Normalizes the significand without needing to extract the exponent. As a by-product, returns a
 value that can be used to calculate the result exponent.

 @param        abs_x
 @param[&out]  out_mlz_x : "Modified number of significand leading zeros, mlz_x = lz_x + EXP_BITS."
 @return                   "Normalized significand, justified to the left of the word."

 @require[abs_x] is_regular(abs_x) && !_sign(abs_x)
 @ensure *out_mlz_x <= K
*>
fn SigInt _normalize(ExpInt* out_mlz_x, int p, int w, FInt abs_x) @inline
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

	ExpInt mlz_x = integer::max(bit::lzcnt(abs_x), w);
	*out_mlz_x = mlz_x;
	return (abs_x << mlz_x) | sign_mask(p, w);
}

<*
 Splits a normalized exponent across EXP_MIN.

 @param[&out]  out_lz : "The number of leading zeros that should be in the significand of the result."
 @param        e      : "normalized exponent"
 @return                "modified result exponent d"

 @ensure *out_lz >= 0
*>
fn FInt _split_exponent(ExpInt* out_lz, ExpInt e)
{
	*out_lz = integer::max0(-e);
	return (FInt)integer::max0(e);
}

<*
 Returns true if the result exponent is out of systems exponent range.

 @param w : "exponent width"
 @param d : "modified exponent: d = er - EXP_MIN"
*>
fn bool _exponent_overflow(int w, FInt d)
{
	// Definite overflow if e > EXP_MAX. Obviously er = e' when e' >= EXP_MIN
	// We have d = er - EXP_MIN > EXP_MAX - EXP_MIN.

	return d >= 2 * exp_max(w);
}

macro FInt _reduce_or(FInt high_r, int bits = ...)
{
	$if $defined(bits):
		return (FInt)(high_r << (K - bits) != 0);
	$else
		return (FInt)(high_r != 0);
	$endif
}

fn FInt _get_rounding_RNE(FInt round, FInt sticky, FInt lsb)
{
	return (FInt)_get_rounding_1(RNE, !!round, !!sticky, !!lsb);
}

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

// References
//
// [1] J.-M. Muller et al., Handbook of Floating-Point Arithmetic, 2nd ed.
//     Cham, Switzerland: Birkhäuser, 2018, doi:10.1007/978-3-319-76526-6
//
// [2] G. Revy, "Implementation of Binary Floating-Point Arithmetic on Embedded Integer
//     Processors - Polynomial Evaluation-Based Algorithms and Certified Code Generation,"
//     Ph.D. dissertation, École Normale Supérieure de Lyon (ENS Lyon), Université de Lyon, Lyon, France, 2009.
