module radiance::softfloat::test;
import radiance::softfloat::binary;
import std::math::random, std::io;

const bool LONG_TEST = $feature(LONG_TEST);

fn void print_status() @init @if(env::TESTING)
{
	$if LONG_TEST:
		io::printn("Doing long tests");
	$else
		io::printn("Doing short tests");
	$endif
}

enum BinaryFormats : int (int width, int precision)
{
	BINARY32 {32, 24}
}
const BINARY32 = BinaryFormats.BINARY32;

union Float
{
	float f;
	uint i;
}

alias _Binary32 = Binary{BINARY32};

macro _Binary32 ref_binary32_add_rn(_Binary32 x, _Binary32 y)
{
	Float fr, fx, fy;
	_Binary32 r;
	fx.i = x.i;
	fy.i = y.i;
	fr.f = fx.f + fy.f;
	r.i = fr.i;
	return r;
}

macro _Binary32 binary32_add_rn(_Binary32 x, _Binary32 y)
{
	_Binary32 r;
	r.i = softfloat::binary::add_rn{BINARY32.width, BINARY32.precision}(x.i, y.i);
	return r;
}

// --- addition ---

fn void binary32_addition_rn_special() @test
{
	test_binary_addition_special(binary32_add_rn);
}

fn void binary32_addition_rn_finite() @test
{
	@test_binary_addition_normal_close_case{BINARY32}(ref_binary32_add_rn, binary32_add_rn, false);
	@test_binary_addition_normal_far_case_1{BINARY32}(ref_binary32_add_rn, binary32_add_rn, false);
	@test_binary_addition_normal_far_case_2{BINARY32}(ref_binary32_add_rn, binary32_add_rn, false);
	@test_binary_op2_subnormal{BINARY32}(ref_binary32_add_rn, binary32_add_rn, false);
	@test_binary_op2_mixed{BINARY32}(ref_binary32_add_rn, binary32_add_rn, false);
}

// --- subtraction ---

// fn void binary32_subtraction_rn_special() @test
// {
// 	test_binary_subtraction_special(binary32_add_rn);
// }

fn void binary32_subtraction_rn_finite() @test
{
	@test_binary_addition_normal_close_case{BINARY32}(ref_binary32_add_rn, binary32_add_rn, true);
	@test_binary_addition_normal_far_case_1{BINARY32}(ref_binary32_add_rn, binary32_add_rn, true);
	@test_binary_addition_normal_far_case_2{BINARY32}(ref_binary32_add_rn, binary32_add_rn, true);
	@test_binary_op2_subnormal{BINARY32}(ref_binary32_add_rn, binary32_add_rn, true);
	@test_binary_op2_mixed{BINARY32}(ref_binary32_add_rn, binary32_add_rn, true);
}

