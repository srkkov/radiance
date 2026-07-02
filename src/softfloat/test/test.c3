module radiance::softfloat::test @if(env::TESTING);
import radiance::softfloat::binary;
import std::math::random, std::io;

ulong total_checks;

fn void more_stats() @finalizer
{
	io::printfn("total checks: %d", total_checks);
}

macro _Binary32 binary32_add_rn(_Binary32 x, _Binary32 y)
{
	_Binary32 r;
	r.i = binary::add_rn{BINARY32.width, BINARY32.precision}(x.i, y.i);
	return r;
}

// --- addition ---

// fn void binary32_addition_rn_special() @test
// {
// 	test_binary_addition_special(binary32_add_rn);
// }

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
	BINARY32 {32, 24},
	BINARY64 {64, 53},
}

const BINARY32 @builtin = BinaryFormats.BINARY32;
const BINARY64 @builtin = BinaryFormats.BINARY64;

alias _Binary32 = Binary{BINARY32};
alias _Binary64 = Binary{BINARY64};

union Float
{
	float f;
	uint i;
}
