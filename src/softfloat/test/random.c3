module radiance::softfloat::test <WIDTH, PRECISION>;
import radiance::integer;
import std::math::random;

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

macro _Binary rand_finite(bool sign = ..., bool $subnormal = false)
{
	_Binary r;
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

macro @rand_swap(#x, #y)
{
	if(rand_bool()) @swap(#x, #y);
}
