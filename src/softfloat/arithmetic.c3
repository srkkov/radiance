module radiance::softfloat::binary <WIDTH, PRECISION>;
import radiance::integer;

enum SubnormalInputControl : char
{
	DEFAULT, NOTIFY, FLUSH_TO_ZERO, DYNAMIC
}

enum SubnormalOutputControl
{
	DEFAULT, NOTIFY, FLUSH_TO_ZERO, DYNAMIC
}

enum ExceptionControl
{
	SUPPRESS, GLOBAL, LOCAL
}



macro bool special_operands(FInt abs_x, FInt abs_y,
                            SubnormalInputControl $subnormal_input_control = DEFAULT,
							SubnormalOutputControl $subnormal_output_control = DEFAULT)
{
	//  We have a special input if,
	//  	|x| or |y| is 0 or in [INF..]
	//  or equivalently in unsigned arithmetic
	//  	max(|x| - 1, |y| - 1) >= INF - 1
	return max(abs_x - 1u, abs_y - 1u) >= INF - 1u;
}







fn FInt add_rn(FInt x, FInt y)
{
	FInt	u;
	FInt 	mr, mx, my;
	FInt 	er, ex, ey;
	FInt 	sr, sx, sy;
	FInt 	abs_r, abs_x, abs_y;
	FInt 	max_abs, min_abs;
	FInt 	high_r, high_y, low_y;
	FInt 	bx, by;
	FInt 	guard, sticky, rounding;
	FInt	dm1;
	int		dx;
	int		e_diff, n, lz_r, c;
	bool 	s;
	bool 	nx, ny;

	abs_x = x & ~SIGN_MASK;
	abs_y = y & ~SIGN_MASK;

	// in place sign bits
	sx = x & SIGN_MASK;
	sy = y & SIGN_MASK;

	// effective sign of operation, 0 = addition, 1 = subtraction
	s = sx != sy;

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

	if (special_operands(abs_x, abs_y))
	{
		max_abs = max(abs_x, abs_y);

		// Either one operand is NaN or |x| and |y| are infinities with opposite signs.
		if (max_abs > INF || (s && abs_x == INF && abs_y == INF))
		{
			return QNAN | max_abs;
		}

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
	//  biased_exponent = real_exponent + EXP_MAX - is_normal_bit
	//  real_exponent = biased_exponent - EXP_MAX + is_normal_bit
	//
	// therefore,
	//
	//  e_diff = ex - ey = (bx + EXP_MIN - nx) - (by + EXP_MIN - ny)
	//                   = (bx - nx) - (by - ny)
	//
	// and we save dx = bx - nx since it will be used later. Also note that
	// 
	//  dx = bx - nx
	//     = ex - EXP_MIN
	//     = ex + EXP_MAX - 1
	//

	// biased exponent
	bx = abs_x >> SIG_BITS;
	by = abs_y >> SIG_BITS;

	// is normal bit
	nx = abs_x >= (1 << SIG_BITS);
	ny = abs_y >= (1 << SIG_BITS);

	dx = (int)bx - (int)nx;
	e_diff = dx - ((int)by - (int)ny);

	// Now we contruct the real significand and leave room for 3 guard bits.
	// 3 bits is enough since in the case of cancellation, if we lose more than
	// 1 digit of precision, then we know that e_diff is either 0 or 1, 
	// see [0] for why.
	mx = (((FInt)nx << SIG_BITS) | abs_x.truncate(SIG_BITS)) << 3;
	my = (((FInt)ny << SIG_BITS) | abs_y.truncate(SIG_BITS)) << 3;

	// Represents the width of the real significand plus the guard bits.
	const U = SIG_BITS + 1 + 3;

	// Represents the "usual case" amount of leading zeros after we add or 
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
	//                       = max(-dx + n, 0)
	n = lzcnt(high_r) - V;
	c = (int)(high_r >> U); assert(c == (int)(n < 0));

	lz_r = max(n - dx, 0);
	
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
	//   = max(dx - n - 1, 1)
	// 
	// d - 1 = max(dx - n, 0)
	dm1 = (FInt)max(dx - n, 0);

	// overflow if e > EXP_MAX
	if (dm1 >= 2 * EXP_MAX)
	{
		return sr | INF;
	}

	// round and pack
	abs_r = ((dm1 << SIG_BITS) + u) + rounding;
	return sr | abs_r;

	// Reference List
	//
	// [0] J.-M. Muller et al., Handbook of Floating-Point Arithmetic,
	//     2nd ed. Cham, Switzerland: Birkhäuser, 2018,
	//     pp. 240-245. doi:10.1007/978-3-319-76526-6
}


macro round_pack_abs(int dm1, FInt u, FInt rounding)
{
	return (((FInt)dm1 << SIG_BITS) + u) + rounding;
}

// fn FInt mul_rn(FInt x, FInt y)
// {
// 	FInt	abs_r, abs_x, abs_y, max_abs, min_abs;
// 	FInt	sr;
// 	FInt	inf;
// 	FInt	mpx, mpy;
// 	int		guard, sticky, rounding
// 	FInt 	dm1;
// 	FInt	high_prod, low_prod;
// 	bool 	nx, ny;
// 	int		c;
// 	int 	bx, by;
// 	int		mlz_x, mlz_y;
//
// 	// truncation shift amount
// 	const T = WIDTH - 2 - SIG_BITS;
//
// 	abs_x = x & ~SIGN_MASK;
// 	abs_y = y & ~SIGN_MASK;
//
// 	sr = (x ^ y) & SIGN_MASK;
//
// 	inf = sr | INF;
//
// 	if (special_operands(abs_x, abs_y))
// 	{
// 		max_abs = max(abs_x, abs_y);
// 		min_abs = min(abs_x, abs_y);
//
// 		switch
// 		{
// 			// Either at least one operand is NaN or one operand a zero and the other is inf
// 			case max_abs > INF || (min_abs == 0 && max_abs == INF):
// 				return QNAN | max_abs;
//
// 			// both operands are zero
// 			case max_abs != INF:
// 				return sr;
//
// 			// both operands are inf
// 			default:
// 				return inf;
// 		}
// 	}
//
// 	// biased exponents
// 	bx = abs_x >> SIG_BITS;
// 	by = abs_y >> SIG_BITS;
// 	// ex = bx + EXP_MIN - nx
// 	// ey = by + EXP_MIN - ny
//
// 	// is normal
// 	nx = abs_x >= (1 << SIG_BITS);
// 	ny = abs_y >= (1 << SIG_BITS);
//
// 	// case e >= EXP_MIN:
// 	// result is in normal range
//
// 	mlz_x = max(lzcnt(abs_x), EXP_BITS);
// 	mlz_y = max(lzcnt(abs_y), EXP_BITS);
// 	// lz_x = mlz_x - EXP_BITS
// 	// lz_y = mlz_y - EXP_BITS
//
// 	// normalized significand
// 	mpx = (x << mlz_x) | BIT_KM1;
// 	mpy = (y << mlz_y) | BIT_KM1;
//
// 	low_prod = mul(&high_prod, mpx, mpy);
//
// 	c = high_prod.msb();
//
// 	// e = ex + ey + lz_x + lz_y + c = ex + ey + mlz_x + mlz_y - 2 * EXP_WIDTH + c
// 	// dm1 = d - 1 = e + EXP_MAX - 1 = e - EXP_MIN 
// 	dm1 = (FInt)((((bx - (int)nx) + (by - (int)ny)) - ((mlz_x + mlz_y) - (2 * EXP_WIDTH + EXP_MIN))) + c);
//
// 	// overflow before rounding, e > EXP_MAX
// 	if (dm1 >= 2 * EXP_MAX)
// 	{
// 		return inf;
// 	}
//
// 	// high_prod : low_prod
// 	//                              index T                                        2(k-1) zeros
// 	//								|										 |-----|
// 	//  	c s[0] s[1] s[2] ... s[p-1] ... s[k-2] : s[k-1] s[k] ... s[2p-1] 0 ... 0
//
// 	// truncated significand
// 	m = high_prod >> (T + c);
//
// 	guard = high_prod.bit(T - 1 + c);
// 	sticky = high_prod.bit_or(T - 1 + c) | low_prod.bit_or();
//
// 	rounding = guard & (m | sticky);
//
// 	abs_r = ((dm1 << SIG_BITS) + m) + rounding;
// 	return sr | abs_r;
// }










alias max = integer::max;
alias min = integer::min;
alias mul = integer::umul;
alias lzcnt = integer::lzcnt;
