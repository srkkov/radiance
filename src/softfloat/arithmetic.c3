module radiance::softfloat::binary <WIDTH, PRECISION>;
import radiance::integer;
import std::io;

/*
 The general algorithm to implementing floating point operations is as follows

 1. Detect and handle special inputs (zeros, infinities and NaNs).
     - Compute the absolute value of the inputs, and handle the signs separately.

 2. compute the exact result `r = (s,e)`
     - Extract the biased exponents

 3. round and pack `r` into the floating point format.

 Now we go into slightly more detail.




 Computing the result exponet.

 ##Overflow

 If `e` falls into the subnormal range, that is `e < EXP_MIN`


 Let's call the unbounded result exponent `e`, and the format encoded result exponent `d`.
 In ieee754, the different between `e` and `d`, is that `d` is biased, has limited range,
 and reserves some values for special encodings.

  - `1 <= d <= 2 * EXP_MAX` encodes a normal number with `e = d - EXP_MAX`.
  - 'd = 0' encodes a subnormal number with exponent `e = EXP_MAX`.
  - `d = 0b11...1 <all ones>` then `r` may encode 
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
macro FInt round_nearest_even(FInt round, FInt sticky, FInt lsb)
{
	return round & (lsb | sticky);
}

<*
	Computes rounding for "round to positive infinity" rounding mode. 

	round | sticky || rounding
	--------------------------
	    0 | 0      ||    0
	    0 | 1      ||   !sr
	    1 | 0      ||   !sr  
	    1 | 1      ||   !sr

	@require sticky <= 1, round <= 1, sr == sr & SIGN_MASK
	@ensure return <= 1
*>
macro FInt round_up(FInt round, FInt sticky, FInt sr)
{
	return ~(sr >> KM1) & (round | sticky);
}

<*
	Computes rounding for "round to negative infinity" rounding mode. 

	round | sticky || rounding
	--------------------------
	    0 | 0      ||    0
	    0 | 1      ||    sr
	    1 | 0      ||    sr  
	    1 | 1      ||    sr

	@require sticky <= 1, round <= 1, sr == sr & SIGN_MASK
	@ensure return <= 1
*>
macro FInt round_down(FInt round, FInt sticky, FInt sr)
{
	return (sr >> KM1) & (round | sticky);
}

<*
 At least one |xs[i]| is in [0..0] or [INF..]
*>
macro bool _special_operands(...)
{
	FInt[$vaarg.len] args; 
	FInt arg;
	$for sz $i; $i < $vaarg.len; $i++:
		arg = $vaarg[$i];
		assert(arg & SIGN_MASK == 0);
		args[$i] = arg - (FInt)1;
	$endfor
	return integer::max(...args) >= INF - (FInt)1;
}

<*
 At least one |xs[i]| is in [0..MAX_SUBNORMAL] or [INF..]
*>
macro bool _special_or_subnormal_operands(...)
{
	uint[$vaarg.len] args; 
	$for sz $i; $i < $vaarg.len; $i++:
		uint arg = $vaarg[$i];
		assert(arg & SIGN_MASK == 0);
		args[$i] = arg - (FInt)1;
	$endfor
	return integer::max(...args) >= INF - (FInt)1;
}

fn FInt add_rn(FInt x, FInt y)
{
	FInt  u;
	FInt  mr, mx, my;
	FInt  er, ex, ey;
	FInt  sr, sx, sy;
	FInt  abs_r, abs_x, abs_y;
	FInt  max_abs, min_abs;
	FInt  high_r, high_y, low_y;
	FInt  bx, by;
	FInt  guard, sticky, rounding;
	FInt  dm1;
	int	  t;
	int	  e_diff, n, lz_r, c;
	bool  s;
	bool  nx, ny;

	abs_x = _abs(x);
	abs_y = _abs(y);

	// in place sign bits
	sx = x & SIGN_MASK;
	sy = y & SIGN_MASK;

	// effective sign of operation, 0 = addition, 1 = subtraction
	s = sx != sy;

	// For rounding modes {rn, rz, ru}
	// The sign of addition of zeros is as follows
	//   sr = sx & sy
	// For rounding modes {rd}, it's
	//   sr = sx | sy

	// RN_even sign handling
	switch 
	{
		case abs_x > abs_y:
			sr = sx;
		case abs_x < abs_y:
			sr = sy;
		default:
			sr = s ? 0 : sx;
	}

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = max(abs_x, abs_y);

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

	if (abs_x < abs_y)
	{
		@swap(abs_x, abs_y);
	}

	// We do not normalize subnormal inputs, since the possibility of cancellation
	// means we have to normalize the result anyway.
	// Now we calculate the exponent difference. Note that
	//
	//  real_exponent = biased_exponent + EXP_MIN - is_normal_bit
	//  biased_exponent = real_exponent - EXP_MIN + is_normal_bit
	//
	// therefore,
	//
	//   e_diff = ex - ey = (bx + EXP_MIN - nx) - (by + EXP_MIN - ny)
	//                    = (bx - nx) - (by - ny)
	//
	// and we save t = bx - nx since it will be used later. Also note that
	// 
	//   t = bx - nx
	//     = ex - EXP_MIN
	//     = ex + EXP_MAX - 1
	//

	bx = _biased_exponent(abs_x);
	by = _biased_exponent(abs_y);

	nx = _normal_bit(abs_x);
	ny = _normal_bit(abs_y);

	t = (int)bx - (int)nx;
	e_diff = t - ((int)by - (int)ny);

	// Now we contruct the real significand and leave room for 3 guard bits.
	// 3 bits is enough since in the case of cancellation, if we lose more than
	// 1 digit of precision, then we know that e_diff is either 0 or 1, 
	// see [0] for why.
	mx = (((FInt)nx << FRAC_BITS) | abs_x.truncate(FRAC_BITS)) << 3;
	my = (((FInt)ny << FRAC_BITS) | abs_y.truncate(FRAC_BITS)) << 3;

	// Represents the width of the real significand plus the guard bits.
	const U = FRAC_BITS + 1 + 3;

	// Represents the standard case amount of leading zeros after we add or 
	// subtract the real significands.
	const V = WIDTH - U;

	// We align the significands, again we only need 3 extra bits, so that is
	// the only part of the shift we are keeping. We are also able to compute
	// a partial sticky of the bits we did not keep before/during the
	// addition/subtraction. Again see [0] for why.
	high_y = my >> min(WIDTH - 1, e_diff);

	switch 
	{
		// no bits discarded
		case e_diff <= 3:
			low_y = 0;

		// all bits discarded, but since my is nonzero, sticky is 1
		case e_diff >= U:
			low_y = 1;

		// some bits discarded, we directly compute the sticky of the discarded bits
		default:
			low_y = my.bit_or(e_diff);
	}

	// Significand addition/subtraction with partial sticky.
	high_y |= low_y;
	high_r = mx + (s ? -high_y : high_y);

	// We calculate the number of leading zeros in the significand. This tells
	// us if we have a carry or cancellation. Then the unbounded exponent of
	// the result is e = ex - n. We then calculate the number of leading zeros
	// that the result significand should have regarding subnormals.
	//
	//  result_leading_zeros = max(EXP_MIN - e, 0)
	//                       = max(EXP_MIN - ex + n, 0)
	//                       = max(-t + n, 0)
	n = lzcnt(high_r) - V;
	c = (int)(high_r >> U);

	lz_r = max(n - t, 0);
	
	high_r <<= n + c - lz_r;

	u = high_r >> (3 + c);

	guard = high_r.bit(2 + c);
	sticky = high_r.bit_or(2 + c);

	rounding = guard & (u | sticky);

	// Instead of computing the result biased exponent d, we compute d - 1,
	// the reason is because in the case that the result is normal, we can
	// avoid removing the hidden bit from the truncated result significand
	// and have it increment the biased exponent field during packing. In
	// the case where the result is subnornmal, the hidden bit is 0, and
	// since e = EXP_MIN, d - 1 will be the correct encoding that indicates
	// a subnormal number. Computing d - 1 is also faster.
	//
	// d = max(e, EXP_MIN) + EXP_MAX
	//   = max(ex - n, EXP_MIN) + EXP_MAX
	//   = max(ex - n + EXP_MAX, EXP_MIN + EXP_MAX)
	//   = max(t - n - 1, 1)
	// 
	// d - 1 = max(t - n, 0)
	dm1 = (FInt)max(t - n, 0);

	// overflow if e > EXP_MAX
	if (dm1 >= 2 * EXP_MAX)
	{
		return sr | INF;
	}

	// round and pack
	abs_r = ((dm1 << FRAC_BITS) + u) + rounding;
	return sr | abs_r;
}

/*
	Consider the multiplication of positive normal numbers x = (mx,ex) and y = (my,ey). Let l = (q,e) 
	be the exact product.
	
	  q * 2^e = (mx * 2^ex) * (my * 2^ey) = mx*my * 2^(ex + ey)
	 
	  q = mx * my,    e = ex + ey
	
	Since x and y are normal numbers 1 <= mx,my < 2 and thus their product is bounded 1 <= q < 4.
	A total of 2*p bits of significand are generated.
	
	  q = c l[0] . l[1] l[2] ... l[2*p]
	
	There may be at most a 1 bit normalization, depending on the value of c.
	
	  q' = mx * my * 2^(-c),    e' = ex + ey + c
	
	Now if we allow subnormal inputs, we simply normalize them beforehand, and continue.
	
	  x' = x * 2^lz_x,    y' = x * 2^lz_y
	
	  q' = mx' * my' * 2^(-c),    e' = ex + ey + c - lz_x - lz_y
	
	Lets start by computing the normalized significands mx' and my'. We must be prepared to 
	to split the product across two words, therefore we would like our significands to be 
	shifted all the way to the left. Say x is normal, then we acheive mx' by shifting x
	EXP_BITS to the left, and adding the implicit bit at the end. If x is subnormal, then
	we shift by an additional lz_x bits. This is achieved by computing

	  mlz_x = max(lzcnt(|x|), EXP_BITS)
	        = lz_x + EXP_BITS
	
	So now we can compute e'
	
	  e' = (bx + EXP_MIN - nx) + (by + EXP_MIN - ny) + c - (mlz_x + mlz_y) + 2 * EXP_BITS
	
	Just like before, d - 1 = max(e' - EXP_MIN, 0) and lz_r = max(EXP_MIN - e', 0)
	
	  t = e' - EXP_MIN
	    = (bx - nx) + (by - ny) + c - (mlz_x + mlz_y) + 2 * EXP_BITS + EXP_MIN

	And at the same time, compute normalized significands mx' and my'. We must also be prepared 
	to split the product across two words, therefore we would like our significands to be shifted all the way to the left.

	Say x is normal, then this involves shifting right by EXP_WIDTH and then adding the implicit leading bit at the end.
	In the subnormal case, we must shift by an additionl lz_x bits, totaling to max(lzcnt(abs_x)



*/

fn FInt mul_rn(FInt x, FInt y)
{
	FInt  abs_r, abs_x, abs_y, max_abs, min_abs;
	FInt  sr;
	FInt  inf;
	FInt  mx, my, u;
	FInt  round, sticky, rounding;
	FInt  dm1;
	FInt  bx, by;
	FInt  high_prod, low_prod;
	bool  nx, ny;
	int   t, s;
	int   c;
	int   mlz_x, mlz_y, lz_r;

	abs_x = _abs(x);
	abs_y = _abs(y);

	sr = (x ^ y) & SIGN_MASK;

	inf = sr | INF;

	if (_special_operands(abs_x, abs_y))
	{
		max_abs = max(abs_x, abs_y);
		min_abs = min(abs_x, abs_y);

		switch
		{
			// Either at least one operand is NaN or one operand a zero and the other is inf
			case max_abs > INF || (min_abs == 0 && max_abs == INF):
				return QNAN | max_abs;

			// both operands are zero
			case max_abs != INF:
				return sr;

			// both operands are inf
			default:
				return inf;
		}
	}

	bx = _biased_exponent(abs_x);
	by = _biased_exponent(abs_y);

	nx = _normal_bit(abs_x);
	ny = _normal_bit(abs_y);

	mlz_x = max(lzcnt(abs_x), EXP_BITS);
	mlz_y = max(lzcnt(abs_y), EXP_BITS);

	// create normalized significands
	mx = (abs_x << mlz_x) | SIGN_MASK;
	my = (abs_y << mlz_y) | SIGN_MASK;

	low_prod = mul(&high_prod, mx, my);

	c = (int)high_prod.msb();

	t = ((int)bx - (int)nx) + ((int)by - (int)ny) - (mlz_x + mlz_y) + 2 * EXP_BITS + EXP_MIN + c;

	dm1 = (FInt)max(t, 0);

	lz_r = max(-t, 0);

	// overflow before rounding
	if (dm1 >= 2 * EXP_MAX)
	{
		return inf;
	}

	// high_prod : low_prod
	//                                                                                     2(k-1) zeros
	//                                                                                     |-----|
	//  	c s[0] . s[1] s[2] ... s[p-1] s[p] s[p+1] ... s[k-2] : s[k-1] s[k] ... s[2p-1] 0 ... 0

	// truncate to s[p-1 - lz_r - c] -> bit k-2 - (p-1) + lz_r + c

	// rounding

	s = min(lz_r + c, K-1);

	u = (high_prod >> (K-2 - (P-1))) >> s;

	round = (high_prod >> (K-2 - P)).bit(s);

	sticky = high_prod.bit_or(min(K-2 - (P+2) + lz_r + c, K-1)) | low_prod.bit_or();

	rounding = round & (u | sticky);

	abs_r = _round_pack(u, dm1, rounding);

	return sr | abs_r;
}

// fn FInt div_rn(FInt x, FInt y)
// {
// 	FInt abs_x, abs_y;
//
//
// 	// (abs_max == abs_min && (abs_max == 0) || (abs_max == INF))
// 	// 	return QNAN | abs_max;
//
// 	if (_special_operands(abs_x, abs_y))
// 	{
// 		max_abs = max(abs_x, abs_y);
// 		min_abs = min(abs_x, abs_y);
//
//
// 	}
//
// }

// <*
//  Computes the correcty rounded value of sqrt(x) for regular inputs.
//  cannot overflow or underflow.
//
//  IEEE754-2019 compliant with the `squareRoot` arithmetic operation in rounding modes:
//   - roundTiesToEven
//
//  @require PRECISION <= EXP_MAX
// *>
// fn FInt sqrt_rn(FInt x)
// {
// 	FInt abs_x;
//
// 	abs_x = _abs(x);
//
// 	sr = x & SIGN_MASK;
//
//
// 	if (_special_operand())
// 	switch
// 	{
// 		case abs_x == 0:
// 			return x;
//
// 		case abs_x == INF && !sr:
// 			return x;
//
// 		case abs
//
// 		case sr:
// 			return x;
// 		case abs_x == 0 || abs_x == INF:
// 			return x;
// 	}
// }


<*
 Extracts the *biased exponent* field of the absolute value of an ieee754 binary 
 floating point bit representation.

 Example for binary32:

	abs_x  = 0 eeeeeeee fffffffffffffffffffffff
	return = 0 00000000 000000000000000eeeeeeee

 @require is_regular(abs_x)
 @ensure return < (FInt)1 << EXP_BITS
*>
macro FInt _biased_exponent(FInt abs_x) @private
{
	return abs_x >> FRAC_BITS;
}

<*
 Returns true if the given absolute value of an ieee754 binary 
 floating point is a normal number.

 @require is_regular(abs_x)
*>
macro bool _normal_bit(FInt abs_x) @private
{
	return abs_x >= MIN_NORMAL;
}

<*
 Ya.
*>
macro FInt _abs(FInt x) @private
{
	return x & ~SIGN_MASK;
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


//
// fn FInt sqrt_rn(FInt x, FInt y)
//
// fn FInt fma_rn(FInt x, FInt y, FInt z)
//
// fn FInt fmma_rn(FInt x, FInt y, FInt z, FInt w)


alias max = integer::max;
alias min = integer::min;
alias mul = integer::mul;
alias lzcnt = integer::lzcnt;

// Don't make fun of me I didn't go to college.

// Sources
//
// [1] J.-M. Muller et al., Handbook of Floating-Point Arithmetic, 2nd ed. 
//     Cham, Switzerland: Birkhäuser, 2018, doi:10.1007/978-3-319-76526-6
//
// [2] G. Revy, "Implementation of Binary Floating-Point Arithmetic on Embedded Integer 
//     Processors - Polynomial Evaluation-Based Algorithms and Certified Code Generation," 
//     Ph.D. dissertation, École Normale Supérieure de Lyon (ENS Lyon), Université de Lyon, Lyon, France, 2009.










