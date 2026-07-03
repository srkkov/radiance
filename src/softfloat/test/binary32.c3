module radiance::softfloat::test::binary32;
import radiance::softfloat::binary;

macro _Binary32 my_add(_Binary32 x, _Binary32 y)
{
	_Binary32 r;
	r.i = binary::add_rn{K,P}(x.i, y.i);
	return r;
}

alias ref_add = test::native_binary32_add_rn;

fn void add_normal_operands() @test
{
	@test_add_normal_close_case{K,P}(ref_add, my_add, false);
	@test_add_normal_far_case_1{K,P}(ref_add, my_add, false);
	@test_add_normal_far_case_2{K,P}(ref_add, my_add, false);
}

fn void add_mixed_operands() @test
{
	@test_op2_mixed{K,P}(ref_add, my_add, false);
}

fn void add_subnormal_operands() @test
{
	@test_op2_subnormal{K,P}(ref_add, my_add, false);
}

fn void sub_normal_operands() @test
{
	@test_add_normal_close_case{K,P}(ref_add, my_add, true);
	@test_add_normal_far_case_1{K,P}(ref_add, my_add, true);
	@test_add_normal_far_case_2{K,P}(ref_add, my_add, true);
}

fn void sub_mixed_operands() @test
{
	@test_op2_mixed{K,P}(ref_add, my_add, true);
}

fn void sub_subnormal_operands() @test
{
	@test_op2_subnormal{K,P}(ref_add, my_add, true);
}

const K = 32;
const P = 24;

alias _Binary32 = _Binary{K,P};
