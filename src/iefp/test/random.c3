module radiance::flt::binary @feat(TESTING);
import std::math::random;

Msws64Random random;

fn void init_random() @init => random.set_seed({1, 2, 3, 4});

fn bool rand_bool() => !!(random.next_int() & 1);

macro @rand_swap(#x, #y)
{
	if (rand_bool()) @swap(#x, #y);
}

<*
 @require upper >= lower
*>
fn int rand_int(int lower, int upper)
{
	uint range = (uint)(upper - lower + 1);
	return lower + (int)((uint)random.next_int() % range);
}

macro @generate_int(Integer min, Integer max; @body(Integer output)) <Integer>
{
	for (Integer i = min; i <= max; i++)
	{
		@body(i);
	}
}

module radiance::flt::binary <WIDTH, PRECISION> @feat(TESTING);
import radiance::integer @public, radiance::integer::bit @public;

fn FInt rand_fint()
{
	FInt r;
	$switch WIDTH:
		$case 8:
			r = random.next_char();
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
	$endswitch
	return r;
}

<*
 @require 0 <= bits, bits <= WIDTH
*>
fn FInt rand_bits(int bits)
{
	int s = WIDTH - bits;
	return (rand_fint() << s) >> s;
}

<*
 @require 0 <= lz, lz < FRAC_BITS
 @ensure return <= integer::max_unsigned_bits(FRAC_BITS)
*>
fn FInt rand_fraction_leading_zeros(int lz)
{
	return bit::bit{FInt}(FRAC_BITS - lz - 1) | rand_fint() >> (WIDTH - FRAC_BITS + lz);
}

<*
 @require 0 <= tz, tz < FRAC_BITS
 @ensure return <= integer::max_unsigned_bits(FRAC_BITS)
*>
fn FInt rand_fraction_trailing_zeros(int tz)
{
	return bit::bit{FInt}(tz) | bit::isolate_low(rand_fint() << tz, FRAC_BITS);
}

fn FInt rand_fraction_bitspan()
{
	
	int i = rand_int(0, FRAC_BITS - 1);
	int j = rand_int(0, FRAC_BITS - 1);

	integer::@minmax(i, j);

	return bit::mask{FInt}(j - i + 1, i);
}

// ============
//  Generators
// ============

<*
 @require 0 <= bits, bits <= WIDTH
*>
macro @generate_bitint(int bits; @body(FInt output))
{
	for (FInt i; i < (FInt)1 << bits; i++)
	{
		@body(i);
	}
}

<*
 @require 0 <= bits, bits <= WIDTH
*>
macro @generate_bit(int bits; @body(FInt output))
{
	for (int i; i < bits; i++)
	{
		@body((FInt)1 << i);
	}
}

<*
 @require 0 <= bits, bits <= WIDTH
*>
macro @generate_bitspan_right(int bits; @body(FInt output))
{
	for (int i = 1; i <= bits; i++)
	{
		@body(bit::mask{FInt}(i));
	}
}

<*
 @require 0 <= bits, bits <= WIDTH
*>
macro @generate_bitspan_left(int bits; @body(FInt output))
{
	for (int i = 1; i <= bits; i++)
	{
		@body(bit::mask{FInt}(i) << (WIDTH - i));
	}
}



