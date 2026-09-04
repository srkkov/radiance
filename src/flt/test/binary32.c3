module radiance::flt::test @feat(TESTING);
import radiance::flt::binary;

long total_checks;

fn void print_check_count() @finalizer
{
	dump(total_checks);
}


fn _Binary32 flt_binary32_add(_Binary32 x, _Binary32 y)
{
	return {.i = binary::add2{K,P}(x.i, y.i, false)};
}

fn _Binary32 flt_binary32_sub(_Binary32 x, _Binary32 y)
{
	return {.i = binary::add2{K,P}(x.i, y.i, true)};
}

fn _Binary32 flt_binary32_mul(_Binary32 x, _Binary32 y)
{
	return {.i = binary::mul2{K,P}(x.i, y.i)};
}

alias ref_binary32_add = native_binary32_add;
alias ref_binary32_mul = native_binary32_mul;

// fn void binary32_multiplication() @test
// {
// 	binary::test_multiplication{K,P}(&ref_binary32_mul, &flt_binary32_mul);
// }

// fn void binary32_addition() @test
// {
// 	binary::test_addition{K,P}(&ref_binary32_add, &flt_binary32_add, false);
// }
//
// fn void binary32_subtraction() @test
// {
// 	binary::test_addition{K,P}(&ref_binary32_add, &flt_binary32_add, true);
// }

// fn void binary32_addition_properties() @test
// {
// 	binary::test_addition_self{K,P}(flt_binary32_add, flt_binary32_sub);
// }







const K @local = 32;
const P @local = 24;

alias _Binary32 = _Binary{K,P};
