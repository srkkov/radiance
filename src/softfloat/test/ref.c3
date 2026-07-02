module radiance::softfloat::test @if(env::TESTING);
import std::io;
import mpfr;

macro _Binary32 @ref_binary32_1op2_rn(#mpfr_op2, _Binary32 x, _Binary32 y)
{
	assert(!t0f.set_binary32(x));
	assert(!t1f.set_binary32(y));

	t0f.subnormalize(#mpfr_op2(t0f, t0f, t1f));

	return t0f.get_binary32();
}

macro _Binary32 ref_binary32_add_rn(_Binary32 x, _Binary32 y) => @ref_binary32_1op2_rn(mpfr::add, x, y);
macro _Binary32 ref_binary32_sub_rn(_Binary32 x, _Binary32 y) => @ref_binary32_1op2_rn(mpfr::sub, x, y);
macro _Binary32 ref_binary32_mul_rn(_Binary32 x, _Binary32 y) => @ref_binary32_1op2_rn(mpfr::mul, x, y);
macro _Binary32 ref_binary32_div_rn(_Binary32 x, _Binary32 y) => @ref_binary32_1op2_rn(mpfr::div, x, y);


fn MpfrTernary Mpfr.set_binary32(&self, _Binary32 x)
{
	return self.set_float(bitcast(x, float));
}

fn _Binary32 Mpfr.get_binary32(&self)
{
	return bitcast(self.get_float(), _Binary32);
}

Mpfr* t0f @builtin;
Mpfr* t1f @builtin;
Mpfr* t2f @builtin;
Mpfr* t3f @builtin;

fn void mpfr_init() @init
{
	static Mpfr _t0f, _t1f, _t2f, _t3f;
	// static Mpfr _t0d, _t1d, _t2d, _t3d;

	t0f = &_t0f;  // t0d = &_t0d;
	t1f = &_t1f;  // t1d = &_t1d;
	t2f = &_t2f;  // t2d = &_t2d;
	t3f = &_t3f;  // t3d = &_t3d;


	assert(mpfr::bound_exponent_ieee754(8, 24));
	mpfr::init(t0f, t1f, t2f, t3f, prec: 24);
}





