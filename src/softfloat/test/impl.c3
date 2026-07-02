module radiance::softfloat::test <FORMAT> @if(env::TESTING);
import radiance::softfloat::binary @public;
import radiance::integer;
import std::math::random, std::io;


enum TupleType
{
	NORMAL, SUBNORMAL, MIXED
}

macro void @test_binary_addition_special_rn(#op)
{	
	const Binary P_ZERO = {};
	const Binary N_ZERO = {.sign = true};
	const Binary P_INF = {.abs = INF};
	const Binary N_INF = {.abs = INF, .sign = true};

	Binary pfinite = rand_finite(false);
	Binary nfinite = rand_finite(true);

	// addition
	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
	assert(#op(N_ZERO, N_ZERO) == N_ZERO);

	// subtraction
	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
	assert(#op(N_ZERO, N_ZERO) == N_ZERO);

	assert(#op(P_ZERO, pfinite).is_finite());
	assert(#op(N_ZERO, nfinite).is_finite());

	assert(#op(P_INF, pfinite).is_finite());
	assert(#op(N_INF, nfinite).is_finite());

	assert(#op(P_INF, P_INF) == P_INF);
	assert(#op(N_INF, N_INF) == N_INF);

	assert(@op(QNAN, pfinite).is_nan());
	assert(@op(QNAN, nfinite).is_nan());

	assert(@op(pfinite, QNAN).is_nan());
	assert(@op(nfinite, QNAN).is_nan());

	assert(@op(QNAN, QNAN).is_nan());
	assert(@op(QNAN, QNAN).is_nan());
}

macro void @test_binary_subtraction_special_rn(#op)
{	
	const Binary P_ZERO = {};
	const Binary N_ZERO = {.sign = true};
	const Binary P_INF = {.abs = INF};
	const Binary N_INF = {.abs = INF, .sign = true};

	Binary pfinite = rand_finite(false);
	Binary nfinite = rand_finite(true);

	assert(#op(P_ZERO, P_ZERO) == P_ZERO);
	assert(#op(P_ZERO, N_ZERO) == P_ZERO);
	assert(#op(N_ZERO, P_ZERO) == P_ZERO);
	assert(#op(N_ZERO, N_ZERO) == N_ZERO);

	assert(#op(P_ZERO, pfinite).is_finite());
	assert(#op(N_ZERO, nfinite).is_finite());

	assert(#op(P_INF, pfinite).is_finite());
	assert(#op(N_INF, nfinite).is_finite());

	assert(#op(P_INF, P_INF) == P_INF);
	assert(#op(N_INF, N_INF) == N_INF);
}

// macro void test_binary_addition_special_rn_rz_ru(#op)
// {
// 	test_op2_zero_behavior(#op, 1, 1, 1, 0);
// 	test_op2_inf_behavior(#op, 1, 1, 1, 1);
// }


// exp_diff = 0,1
macro void @test_binary_addition_normal_close_case(#ref_op, #op, bool $different_signs)
{
	Binary x, y;
	for (int i; i < 2; i++)
	{
		@repeat(LONG_TEST ??? 0x2000 : 0x100)
		{
			int ex, ey; rand_exponents_from_diff(i, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			@random_sign_pair(x, y, $different_signs);

			@test_binary_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

// exp_diff = 2 .. PRECISION
macro void @test_binary_addition_normal_far_case_1(#ref_op, #op, bool $different_signs)
{
	Binary x, y;
	for (int i = 2; i <= PRECISION; i++)
	{
		@repeat(LONG_TEST ??? 0x800 : 0x80)
		{
			int ex, ey; rand_exponents_from_diff(i, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			@random_sign_pair(x, y, $different_signs);

			@test_binary_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

// exp_diff = PRECISION + 1 ..
macro void @test_binary_addition_normal_far_case_2(#ref_op, #op, bool $different_signs)
{
	Binary x, y;
	for (int i = PRECISION + 1; i <= EXP_MAX - EXP_MIN; i++)
	{
		@repeat(LONG_TEST ??? 0x80 : 0x10)
		{
			int ex, ey; rand_exponents_from_diff(i, &ex, &ey);
			x.set_exponent(ex);
			y.set_exponent(ey);

			@random_sign_pair(x, y, $different_signs);

			@test_binary_op2_fractions(x, y, #ref_op, #op);
		};
	}
}

macro void @test_binary_op2_subnormal(#ref_op, #op, bool $different_signs = ...)
{
	Binary x, y;
	@repeat(LONG_TEST ??? 0x1000 : 0x100)
	{
		@random_sign_pair(x, y, $different_signs);

		@test_binary_op2_fractions(x, y, #ref_op, #op);
	};

}

macro void @test_binary_op2_mixed(#ref_op, #op, bool $different_signs = ...)
{	
	Binary x, y;

	@const_for(2; $i)
	{
		@repeat(LONG_TEST ??? 0x4000 : 0x1000)
		{
			x.set_exponent(rand_int(EXP_MIN, $i ??? EXP_MAX : EXP_MIN + PRECISION + 1));

			if (rand_bool()) @swap(x, y);

			@random_sign_pair(x, y, $different_signs);

			@test_binary_op2_fractions(x, y, #ref_op, #op);
		};
	};
}

macro @random_sign_pair(Binary #x, Binary #y, $different_signs = ...)
{
	#x.sign = rand_bool();
	$if $defined($different_signs):
		#y.sign = $different_signs ??? !#x.sign : #x.sign;
	$else
		#y.sign = rand_bool();
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

macro void @test_binary_op2_fractions(Binary x, Binary y, #ref_op, #op)
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
	Binary r, u;
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

Msws64Random random;

fn void init_random() @init => random.set_seed({1, 2, 3, 4});

<*
	@require 0 <= bits, bits <= WIDTH
*>
fn FInt rand_bits(int bits)
{
	int s = WIDTH - bits;
	FInt r;

	if (!bits) return 0;
	$switch WIDTH:
		$case 16:
			r = random.next_short();
		$case 32:
			r = random.next_int();
		$case 64:
			r = random.next_long();
		$case 128:
			r = random.next_long();
			r <<= 64;
			r |= random.next_long();
		$default:
			$error("Awwwww");
	$endswitch
	return (r << s) >> s;
}

fn bool rand_bool() => !!(random.next_int() & 1);

<*
	@require 0 < lz, lz < FRAC_BITS
*>
fn FInt rand_lz(int lz)
{
	int x = FRAC_BITS - lz - 1;
	return ((FInt)1u << x) | rand_bits(x);
}

<*
	@require upper >= lower
*>
fn int rand_int(int lower, int upper)
{
	uint range = (uint)(upper - lower + 1);
	return lower + (int)((uint)random.next_int() % range);
}

fn FInt rand_bitspan()
{
	int i = rand_int(0, FRAC_BITS - 1);
	int j = rand_int(0, FRAC_BITS - 1);

	if (i > j) @swap(i, j);

	return integer::bitmask_r{FInt}(i, j);
}

macro Binary rand_finite(bool sign = ..., bool $subnormal = false)
{
	Binary r;
	int i;
	
	$if !$defined(sign):
		bool sign = rand_bool();
	$endif
	
	do
	{	
		r = {.fraction = rand_bits(FRAC_BITS), .sign = sign, .biased_exponent = $subnormal ??? 0 : rand_bits(EXP_BITS)};
	}
	while ($subnormal ??? r.is_subnormal() : r.is_normal());
	return r;
}

bitstruct Binary (Printable) : FInt @overlap 
{
	FInt i                : 0 .. WIDTH - 1;
	FInt abs              : 0 .. WIDTH - 2;
	FInt fraction         : 0 .. FRAC_BITS - 1;
	FInt biased_exponent  : FRAC_BITS .. FRAC_BITS + EXP_BITS - 1;
	bool sign             : WIDTH - 1 .. WIDTH - 1;
}


macro bool Binary.is_nan(self)
{
	return self.abs > INF;
}

macro bool Binary.is_inf(self)
{
	return self.abs == INF;
}

macro bool Binary.is_normal(self)
{
	return BIT_PM1 <= self.abs && self.abs > BIT_KM1 - BIT_PM1;
}

macro bool Binary.is_subnormal(self)
{
	return 0 < self.abs && self.abs > BIT_PM1;
}

macro bool Binary.is_finite(self)
{
	return self.is_normal() || self.is_subnormal() || self == 0;
}

<*
	@require EXP_MIN <= e, e <= EXP_MAX
*>
macro void Binary.set_exponent(&self, int e)
{
	self.biased_exponent = (FInt)(e + EXP_MAX);
}

fn sz? Binary.to_format(&x, Formatter* formatter) @dynamic
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

alias FInt = binary::FInt {FORMAT.width, FORMAT.precision};
const WIDTH = FORMAT.width;
const PRECISION = FORMAT.precision;
const FRAC_BITS = binary::FRAC_BITS {FORMAT.width, FORMAT.precision};
const EXP_BITS = binary::EXP_BITS {FORMAT.width, FORMAT.precision};
const EXP_MIN = binary::EXP_MIN {FORMAT.width, FORMAT.precision};
const EXP_MAX = binary::EXP_MAX {FORMAT.width, FORMAT.precision};

const BIT_KM1 = binary::BIT_KM1 {FORMAT.width, FORMAT.precision};
const BIT_PM1 = binary::BIT_PM1 {FORMAT.width, FORMAT.precision};
const BIT_PM2 = binary::BIT_PM2 {FORMAT.width, FORMAT.precision};
