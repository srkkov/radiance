module radiance::flt::binary <WIDTH, PRECISION> @feat(TESTING);
import radiance::integer;
import std::io;

alias Op2 = fn _Binary(_Binary,_Binary);

macro void @test_addition_self(#add, #sub, bool $symmetric_rounding = false)
{
	_Binary r0, r1, x, y;
	
	for (int i; i <= PRECISION; i++)
	{
		int ex, ey;
		set_rand_exponents_from_diff(i, &x, &y);

		do
		{
			x.fraction = rand_bits(FRAC_BITS);
			y.fraction = rand_bits(FRAC_BITS);
		}
		while (x.fraction == y.fraction);

		foreach (bool sx : {false, true})
		{
			foreach (bool sy : {false, true})
			{
				x.sign = sx;
				y.sign = sy;

				// ∘(x + y) = ∘(y + x)
				r0 = #add(x, y);
				r1 = #add(y, x);
				@check(r0 == r1, "commutativity of addition");

				// ∘(x + (-y)) = ∘(x - y)
				r0 = #sub(x, y);
				y.negate();
				r1 = #add(x, y);
				@check(r0 == r1, "definition of subtraction");

				// restore
				y.sign = sy;

				$if $symmetric_rounding:

					// ∘(x - y) =  -∘(y - x)
					r0 = #add(x, y);
					r0.negate();
					r1 = #sub(y, x);
					@check(r0 == r1, "anti-commutativity of subtraction, symmetric rounding mode (1)");

					// ∘(x + y) = -∘((-y) + (-x))
					r0 = #add(x, y);
					x.negate();
					y.negate();
					r1 = #add(x, y);
					r1.negate();
					@check(r0 == r1, "symmetric rounding mode (2)");

				$endif

				// restore
				x.sign = sx;
				y.sign = sy;

				// ∘(x + y) = ∘(x - (-y))
				r0 = #add(x, y);
				y.negate();
				r1 = #sub(x, y);
				@check(r0 == r1, "double negative");
			}
		}

		x.biased_exponent = bias_exponent(0);
		y.biased_exponent = bias_exponent(0);
		x.sign = false;
		y.sign = false;

		r0 = #add(x, y);
		@check(r0.sign == false, "x > 0, y > 0 => x + y > 0");

		if (x.fraction < y.fraction)
		{
			@swap(x, y);
		}
		// |x| > |y|	

		// ∘(x - y) > 0
		r0 = #sub(x, y);
		@check(r0.sign == false);

		// ∘(y - x) < 0
		r0 = #sub(y, x);
		@check(r0.sign == true);
	}
}

fn void test_multiplication(Op2 ref_op, Op2 flt_op)
{
	_Binary x, y;
	@repeat(1)
	{
		x.biased_exponent = bias_exponent(rand_int(EXP_MIN, EXP_MIN));
		y.biased_exponent = bias_exponent(rand_int(EXP_MIN, EXP_MIN));
		generate_and_test_fractions_2(x, y, ref_op, flt_op);	
	};
}

fn void test_addition(Op2 ref_op, Op2 flt_op, bool sign)
{
	_Binary x, y;
	y.sign = sign;

	// TODO: Special Inputs

	// Close Case 
	for (int i; i <= 1; i++)
	{
		@repeat(sign ? 2_000 : 800)
		{
			int ex, ey;
			set_rand_exponents_from_diff(i, &x, &y);

			generate_and_test_fractions_2(x, y, ref_op, flt_op);
		};
	}

	// Far Case
	for (int i; i <= PRECISION; i++)
	{
		@repeat(400)
		{
			int ex, ey;
			set_rand_exponents_from_diff(i, &x, &y);

			generate_and_test_fractions_2(x, y, ref_op, flt_op);
		};
	}

	// Very Far Case
	for (int i = PRECISION + 1; i <= EXP_MAX - EXP_MIN; i++)
	{
		@repeat(100)
		{
			int ex, ey;
			set_rand_exponents_from_diff(i, &x, &y);
			generate_and_test_fractions_2(x, y, ref_op, flt_op);
		};
	}

	// 1 Subnormal Operand
	x.biased_exponent = 0;
	for (int i = EXP_MIN; i <= EXP_MAX; i++)
	{
		y.biased_exponent = bias_exponent(i);
		@rand_swap(x, y);
		
		generate_and_test_fractions_2(x, y, ref_op, flt_op);
	}

	// Both Operands are Subnormal
	x.biased_exponent = 0;
	y.biased_exponent = 0;
	generate_and_test_fractions_2(x, y, ref_op, flt_op);
}

fn void set_rand_exponents_from_diff(int exp_diff, _Binary* x, _Binary* y)
{
	int ex, ey;
	ex = rand_int(EXP_MIN, EXP_MAX - exp_diff);
	ey = ex + exp_diff;
	@rand_swap(ex, ey);
	x.biased_exponent = bias_exponent(ex);
	y.biased_exponent = bias_exponent(ey);
}

<*
 @require e >= EXP_MIN, e <= EXP_MAX
*>
fn FInt bias_exponent(int e)
{
	return (FInt)(e + EXP_MAX);
}

// macro @generate_exponents(@body; FInt bx)
// {
// 	_Binary t;
// 	for (int i; i < PRECISION; i++)
// 	{
// 		@body(bias_exponent(EXP_MIN + i));
// 		@body(bias_exponent(EXP_MAX - i));
// 	}
// 	for (int i = -2; i <= 2; i++)
// 	{
// 		@body({.biased_exponent = bias_exponent(EXP_MIN + i)});
// 	}
// }


fn void generate_and_test_fractions_2(_Binary x, _Binary y, Op2 ref_op, Op2 op, int c0 = 64, int c1 = 8)
{
	@generate_fractions(c0, c1; FInt mx)
	{
		x.fraction = mx;
		@generate_fractions(c0, c1; FInt my)
		{
			y.fraction = my;
			test_op2(ref_op, op, x, y);
		};
	};
}

macro @generate_fractions(int c0, int c1; @body(FInt fraction))
{
	// All zeros.
	@body(0);

	// 1 bit set.
	for (int i; i < FRAC_BITS; i++)
	{
		@body((FInt)1 << i);
	}

	// All right bits set.
	for (int i = 2; i < FRAC_BITS; i++)
	{
		@body(bit::mask{FInt}(i));
	}

	// All left bits set.
	for (int i = 2; i < FRAC_BITS; i++)
	{
		@body(bit::mask{FInt}(i, FRAC_BITS - i));
	}

	// All ones.
	@body(~(FInt)0);

	// Small and large fractions (that we have't checked before)
	for (int i; i < 32; i++)
	{
		if (!integer::is_pow2(i) && !integer::is_mersenne(i))
		{
			// Small fractions.
			@body((FInt)i);

			// Large fractions.
			@body(MAX_FRAC - (FInt)i);
		}
	}

	// Fractions with a varying number of leading repeating bits.
	for (int i; i < FRAC_BITS - 5; i++)
	{
		@repeat(c0)
		{
			FInt m = rand_fraction_leading_zeros(i);
			@body(m);
			@body(~m);
		};
	}

	// Fractions with a varying number of trailing repeating bits.
	for (int i; i < FRAC_BITS - 5; i++)
	{
		@repeat(c0)
		{
			FInt m = rand_fraction_trailing_zeros(i);
			@body(m);
			@body(~m);
		};
	}

	//
	// // I don't really know what I'm doing here.
	// @repeat(c1)
	// {
	// 	FInt r = bit::isolate_low(rand_fint(), FRAC_BITS);
	// 	FInt mask = rand_fraction_bitspan();
	//
	// 	@body(r & ~mask);
	// 	@body(r | mask);
	//
	// 	mask ^ rand_fraction_bitspan();
	//
	// 	@body(r & ~mask);
	// 	@body(r | mask);
	// };
	//
	// @repeat(c1)
	// {
	// 	@body(rand_fraction_bitspan() ^ rand_fraction_bitspan());
	// };
}

import radiance::flt::test;

macro void @test_op(#ref_op, #op, ...)
{
	test::total_checks++;
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
		test::eq(0, 1);
	}
}

fn void test_op2(Op2 ref_op, Op2 op, _Binary x, _Binary y)
{
	@test_op(ref_op, op, x, y);
}

macro @check(bool #expr, String name = "")
{
	if (!#expr)
	{
		io::printfn("Check '%s' failed.", name == "" ? $stringify(#expr) : name);
		test::eq(0, 1);
	}
}

const MAX_FRAC = integer::max_unsigned_bits(FRAC_BITS);
