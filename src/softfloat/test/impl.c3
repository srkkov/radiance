module radiance::softfloat::test <WIDTH, PRECISION> @if(env::TESTING);
import radiance::softfloat::binary @public;
import radiance::integer;
import std::math::random, std::io;


// macro void @test_binary_addition_special_rn(#op)
// {	
// 	const _Binary P_ZERO = {};
// 	const _Binary N_ZERO = {.sign = true};
// 	const _Binary P_INF = {.abs = INF};
// 	const _Binary N_INF = {.abs = INF, .sign = true};
//
// 	_Binary pfinite = rand_finite(false);
// 	_Binary nfinite = rand_finite(true);
//
// 	// addition
// 	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, N_ZERO) == N_ZERO);
//
// 	// subtraction
// 	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, N_ZERO) == N_ZERO);
//
// 	assert(#op(P_ZERO, pfinite).is_finite());
// 	assert(#op(N_ZERO, nfinite).is_finite());
//
// 	assert(#op(P_INF, pfinite).is_finite());
// 	assert(#op(N_INF, nfinite).is_finite());
//
// 	assert(#op(P_INF, P_INF) == P_INF);
// 	assert(#op(N_INF, N_INF) == N_INF);
//
// 	assert(@op(QNAN, pfinite).is_nan());
// 	assert(@op(QNAN, nfinite).is_nan());
//
// 	assert(@op(pfinite, QNAN).is_nan());
// 	assert(@op(nfinite, QNAN).is_nan());
//
// 	assert(@op(QNAN, QNAN).is_nan());
// 	assert(@op(QNAN, QNAN).is_nan());
// }
//
// macro void @test_binary_subtraction_special_rn(#op)
// {	
// 	const _Binary P_ZERO = {};
// 	const _Binary N_ZERO = {.sign = true};
// 	const _Binary P_INF = {.abs = INF};
// 	const _Binary N_INF = {.abs = INF, .sign = true};
//
// 	_Binary pfinite = rand_finite(false);
// 	_Binary nfinite = rand_finite(true);
//
// 	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
// 	assert(#op(N_ZERO, N_ZERO) == N_ZERO);
//
// 	assert(#op(P_ZERO, pfinite).is_finite());
// 	assert(#op(N_ZERO, nfinite).is_finite());
//
// 	assert(#op(P_INF, pfinite).is_finite());
// 	assert(#op(N_INF, nfinite).is_finite());
//
// 	assert(#op(P_INF, P_INF) == P_INF);
// 	assert(#op(N_INF, N_INF) == N_INF);
// }

<*
 Tests 2 operands that have an exponent difference equal to `0` or `1`.
 Mainly used for addition/subtraction testing.
*>
macro void @test_add_normal_close_case(#ref_op, #op, bool $different_signs)
{
	_Binary x, y;
	for (int i; i < 2; i++)
	{
		@repeat(LONG_TEST ??? 40_000 : 800)
		{
			int ex, ey; rand_exponents_from_diff(i, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			random_sign_pair(&x, &y, $different_signs);

			@test_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

<*
 Tests 2 operands that have an exponent difference equal between `2` and `PRECISION`.
 Mainly used for addition/subtraction testing.
*>
macro void @test_add_normal_far_case_1(#ref_op, #op, bool $different_signs)
{
	_Binary x, y;
	for (int i = 2; i <= PRECISION; i++)
	{
		@repeat(LONG_TEST ??? 20_000 : 400)
		{
			int ex, ey; rand_exponents_from_diff(i, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			random_sign_pair(&x, &y, $different_signs);

			@test_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

<*
 Tests 2 operands that have an exponent difference higher than `PRECISION`.
 Mainly used for addition/subtraction testing.
*>
macro void @test_add_normal_far_case_2(#ref_op, #op, bool $different_signs)
{
	_Binary x, y;
	int ex, ey;
	for (int exp_diff = PRECISION + 1; exp_diff <= EXP_MAX - EXP_MIN; exp_diff++)
	{
		@repeat(LONG_TEST ??? 10_000 : 100)
		{
			rand_exponents_from_diff(exp_diff, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			random_sign_pair(&x, &y, $different_signs);

			@test_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

<*
 Tests some subnormal operands pairs, exluding the sign.
*>
macro void @test_op2_subnormal(#ref_op, #op, bool $different_signs = ...)
{
	_Binary x, y;

	$if $defined($different_signs):
		$if $different_signs:
			x.sign = true;
			@test_op2_fractions(x, y, #ref_op, #op);
			x.sign = false; y.sign = true;
			@test_op2_fractions(x, y, #ref_op, #op);
		$else
			@test_op2_fractions(x, y, #ref_op, #op);
			x.sign = true; y.sign = true;
			@test_op2_fractions(x, y, #ref_op, #op);
		$endif
	$else
		@test_op2_fractions(x, y, #ref_op, #op);
		y.sign = true;
		@test_op2_fractions(x, y, #ref_op, #op);
		x.sign = true; y.sign = false;
		@test_op2_fractions(x, y, #ref_op, #op);
		y.sign = true;
		@test_op2_fractions(x, y, #ref_op, #op);
	$endif
}

<*
 Tests all subnormal operands pairs, exluding the sign.
*>
macro void @test_op2_all_subnormals(#ref_op, #op)
{
	_Binary x, y;
	for (FInt i; i < FRAC_BITS; i++)
	{
		x.fraction = i;
		for (FInt j; j < FRAC_BITS; j++)
		{	
			y.fraction = j;
			@test_op(#ref_op, #op, x, y);
		}
	}
}

<*
 Tests 2 operands, one subnormal operand, and one normal operand. First we test 
 all normal exponents, then we test exponents near EXP_MIN.
*>
macro void @test_op2_mixed(#ref_op, #op, bool $different_signs = ...)
{	
	_Binary x, y;
	foreach (int emax : {EXP_MAX, EXP_MIN + PRECISION + 1})
	{
		@repeat(LONG_TEST ??? 400_000 : 8_000)
		{
			x.set_exponent(rand_int(EXP_MIN, emax));

			@rand_swap(x, y);

			random_sign_pair(&x, &y, $different_signs);

			@test_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

macro random_sign_pair(_Binary* x, _Binary* y, $different_signs = ...)
{
	x.sign = rand_bool();
	$if $defined($different_signs):
		y.sign = $different_signs ??? !x.sign : x.sign;
	$else
		y.sign = rand_bool();
	$endif
}

fn void rand_exponents_from_diff(int exp_diff, int* out_ex, int* out_ey)
{
	int ex, ey;
	ex = rand_int(EXP_MIN, EXP_MAX - exp_diff);
	ey = ex + exp_diff;
	if (rand_bool()) @swap(ex, ey);
	*out_ex = ex;
	*out_ey = ey;
}

macro void @test_op2_fractions(_Binary x, _Binary y, #ref_op, #op)
{
	@for_type1_fractions(; FInt mx)
	{
		@for_type1_fractions(; FInt my)
		{
			x.fraction = mx;
			y.fraction = my;

			@test_op(#ref_op, #op, x, y);
		};
	};

	@for_type2_fractions(; FInt mx)
	{
		@for_type2_fractions(; FInt my)
		{
			x.fraction = mx;
			y.fraction = my;

			@test_op(#ref_op, #op, x, y);
		};
	};

	@for_type3_fractions(; FInt mx)
	{
		@for_type3_fractions(; FInt my)
		{
			x.fraction = mx;
			y.fraction = my;

			@test_op(#ref_op, #op, x, y);
		};
	};

	@for_small_fractions(31; FInt mx)
	{
		@for_small_fractions(31; FInt my)
		{
			x.fraction = mx;
			y.fraction = my;

			@test_op(#ref_op, #op, x, y);
		};
	};

	@for_large_fractions(31; FInt mx)
	{
		@for_large_fractions(31; FInt my)
		{
			x.fraction = mx;
			y.fraction = my;

			@test_op(#ref_op, #op, x, y);
		};
	};

	@for_leading_zeros(6; int lz)
	{
		@repeat(1024)
		{
			x.fraction = rand_lz(lz);
			y.fraction = rand_lz(lz);

			@test_op(#ref_op, #op, x, y);
		};
	};

	@repeat(512)
	{
		x.fraction = rand_bitspan();
		y.fraction = rand_bitspan();

		@test_op(#ref_op, #op, x, y);
	};

	@repeat(512)
	{
		x.fraction = rand_bitspan();
		y.fraction = rand_bitspan();

		@test_op(#ref_op, #op, x, y);
	};
}

macro @for_leading_zeros(int lower; @body(lz))
{
	for (int lz = lower; lz < FRAC_BITS; lz++)
	{
		@body(lz);
	}
}

macro @for_small_fractions(sz count; @body(FInt fraction))
{
	for (sz i = 1; i < count; i++)
	{
		@body((FInt)i);
	}
}

macro @for_large_fractions(sz count; @body(FInt fraction))
{
	for (sz i; i < count; i++)
	{
		@body((FInt)(~i));
	}
}

macro @for_type1_fractions(; @body(FInt fraction))
{
	FInt fraction;
	for (int i; i < FRAC_BITS; i++)
	{
		@body(fraction.bit_set(i));
	}
}

macro @for_type2_fractions(; @body(FInt fraction))
{
	FInt fraction;
	for (int i; i < FRAC_BITS; i++)
	{
		fraction = fraction.bit_set(i);
		@body(fraction);
	}
}

macro @for_type3_fractions(; @body(FInt fraction))
{
	FInt fraction;
	for (int i = FRAC_BITS - 1; i >= 0; i--)
	{
		fraction = fraction.bit_set(i);
		@body(fraction);
	}
}

macro void @test_op(#ref_op, #op, ...)
{
	total_checks++;
	_Binary r, u;
	r = #op(...$vaarg);
	u = #ref_op(...$vaarg);
	if (r != u)
	{
		$for sz $i; $i < $vaarg.len; $i++:
			io::printfn($stringify($vaarg[$i]) +++ " = %s", $vaarg[$i]);
		$endfor
		io::printfn("expected = %s", u);
		io::printfn("mine     = %s", r);
		test::eq(1, 0);
	}
}

bitstruct _Binary (Printable) : FInt @overlap 
{
	FInt i                : 0 .. WIDTH - 1;
	FInt abs              : 0 .. WIDTH - 2;
	FInt fraction         : 0 .. FRAC_BITS - 1;
	FInt biased_exponent  : FRAC_BITS .. FRAC_BITS + EXP_BITS - 1;
	bool sign             : WIDTH - 1 .. WIDTH - 1;
}

macro bool _Binary.is_nan(self)
{
	return self.abs > INF;
}

macro bool _Binary.is_inf(self)
{
	return self.abs == INF;
}

macro bool _Binary.is_normal(self)
{
	return BIT_PM1 <= self.abs && self.abs > BIT_KM1 - BIT_PM1;
}

macro bool _Binary.is_subnormal(self)
{
	return 0 < self.abs && self.abs > BIT_PM1;
}

macro bool _Binary.is_finite(self)
{
	return self.is_normal() || self.is_subnormal() || self == 0;
}

<*
	@require EXP_MIN <= e, e <= EXP_MAX
*>
macro void _Binary.set_exponent(&self, int e)
{
	self.biased_exponent = (FInt)(e + EXP_MAX);
}

fn sz? _Binary.to_format(&x, Formatter* formatter) @dynamic
{
	FInt abs = x.abs;
	char sign = x.sign ? '-' : '+';
	String $sig_fmt = @sprintf("%%0%sb", FRAC_BITS);

	switch
	{
		case abs == 0:
			return formatter.printf("%c0." +++ $sig_fmt +++ "p+0", sign, 0)!;

		case abs < BIT_PM1:
			return formatter.printf("%c0." +++ $sig_fmt +++ "p%+d", sign, x.fraction, EXP_MIN)!;
		
		case abs < BIT_KM1 - BIT_PM1:
			return formatter.printf("%c1." +++ $sig_fmt +++ "p%+d", sign, x.fraction, (int)x.biased_exponent - EXP_MAX)!;

		case abs == BIT_KM1 - BIT_PM1:
			return formatter.printf("%cINF", sign)!;

		case abs < BIT_KM1 - BIT_PM2:
			return formatter.printf("%csNaN", sign)!;

		default:
			return formatter.printf("%cqNaN", sign)!;
	}
}

alias FInt = binary::FInt {WIDTH, PRECISION};
const FRAC_BITS = binary::FRAC_BITS {WIDTH, PRECISION};
const EXP_BITS = binary::EXP_BITS {WIDTH, PRECISION};
const EXP_MIN = binary::EXP_MIN {WIDTH, PRECISION};
const EXP_MAX = binary::EXP_MAX {WIDTH, PRECISION};

const BIT_KM1 = binary::BIT_KM1 {WIDTH, PRECISION};
const BIT_PM1 = binary::BIT_PM1 {WIDTH, PRECISION};
const BIT_PM2 = binary::BIT_PM2 {WIDTH, PRECISION};
