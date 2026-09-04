module radiance::integer::test @test;
import radiance::integer @public;
import radiance::test;

fn void is_even()
{
	test::@check(integer::is_even(-2));
	test::@check(integer::is_even(-4));
	test::@check(integer::is_even(0));
	test::@check(integer::is_even(2));
	test::@check(integer::is_even(4));
	test::@check(integer::is_even(int::max - 1));
	test::@check(integer::is_even(int::min));

	test::@check(!integer::is_even(-3));
	test::@check(!integer::is_even(-1));
	test::@check(!integer::is_even(1));
	test::@check(!integer::is_even(3));
	test::@check(!integer::is_even(int::max));
	test::@check(!integer::is_even(int::min - 1));
}

fn void is_odd()
{
	test::@check(!integer::is_odd(-2));
	test::@check(!integer::is_odd(-4));
	test::@check(!integer::is_odd(0));
	test::@check(!integer::is_odd(2));
	test::@check(!integer::is_odd(4));
	test::@check(!integer::is_odd(int::max - 1));
	test::@check(!integer::is_odd(int::min));

	test::@check(integer::is_odd(-3));
	test::@check(integer::is_odd(-1));
	test::@check(integer::is_odd(1));
	test::@check(integer::is_odd(3));
	test::@check(integer::is_odd(int::max));
	test::@check(integer::is_odd(int::min - 1));
}

fn void is_pow2()
{
	test::@check(integer::is_pow2(1));
	test::@check(integer::is_pow2(2));

	for (int i = 2; i < 32; i++)
	{
		uint u = 1u << i;
		test::@check(integer::is_pow2(u));
		test::@check(!integer::is_pow2(u + 1));
		test::@check(!integer::is_pow2(u - 1));
	}

	test::@check(!integer::is_pow2(-8));
	test::@check(!integer::is_pow2(-4));
	test::@check(!integer::is_pow2(-2));
	test::@check(!integer::is_pow2(-1));
	test::@check(!integer::is_pow2(0));
	test::@check(!integer::is_pow2(3));
	test::@check(!integer::is_pow2(5));
	test::@check(!integer::is_pow2(6));
	test::@check(!integer::is_pow2(15));
}

fn void is_mersenne()
{
	test::@check(!integer::is_mersenne(-31));
	test::@check(!integer::is_mersenne(-15));
	test::@check(!integer::is_mersenne(-7));
	test::@check(!integer::is_mersenne(-3));
	test::@check(!integer::is_mersenne(-2));
	test::@check(!integer::is_mersenne(-2));
	test::@check(!integer::is_mersenne(-1));
	test::@check(!integer::is_mersenne(0));
	test::@check(!integer::is_mersenne(2));
	test::@check(!integer::is_mersenne(4));
	test::@check(!integer::is_mersenne(6));
	test::@check(!integer::is_mersenne(8));
	test::@check(!integer::is_mersenne(12));
	test::@check(!integer::is_mersenne(16));
	test::@check(!integer::is_mersenne(32));

	test::@check(integer::is_mersenne(1));
	test::@check(integer::is_mersenne(3));
	test::@check(integer::is_mersenne(7));
	test::@check(integer::is_mersenne(15));
	test::@check(integer::is_mersenne(31));
	test::@check(integer::is_mersenne(0xfffff));
}






