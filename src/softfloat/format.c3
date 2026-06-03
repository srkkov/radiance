module radiance::softfloat::binary <WIDTH, PRECISION>;
import radiance::integer;
import std::io;

alias FInt = integer::unsigned_from_bitsize(WIDTH);

const FInt BIT_PM1 @private = 1u << (PRECISION - 1u);
const FInt BIT_PM2 @private = 1u << (PRECISION - 2u);
const FInt BIT_KM1 @private = 1u << (WIDTH - 1u);

const int EXP_BITS 	= WIDTH - PRECISION;
const int SIG_BITS 	= PRECISION - 1;
const int EXP_MAX 	= (1 << (EXP_BITS - 1)) - 1;
const int EXP_MIN 	= 1 - EXP_MAX;
const int BIAS 		= EXP_MAX;

const FInt SIGN_MASK = BIT_KM1;
const FInt SIG_MASK = integer::const_bitmask(FInt, SIG_BITS);

const FInt INF = BIT_KM1 - BIT_PM1;
const FInt QNAN = BIT_KM1 - BIT_PM2;

const FInt MIN_SUBNORMAL = 1u;
const FInt MAX_SUBNORMAL = BIT_PM1 - 1u;
const FInt MIN_NORMAL = BIT_PM1;
const FInt MAX_NORMAL = BIT_KM1 - BIT_PM1 - 1u;

macro abs(FInt x) @local => x & ~SIGN_MASK;

macro bool is_zero(FInt x)
{
	return abs(x) == 0;
}

macro bool is_subnormal(FInt x)
{
	return abs(x) - 1u < BIT_PM1 - 1u;
}

macro bool is_normal(FInt x)
{
	return abs(x) - BIT_PM1 < INF - BIT_PM1;
}

macro bool is_finite_nonzero(FInt x)
{
	return abs(x) - 1u < INF - 1u;
}

macro bool is_finite(FInt x)
{
	return abs(x) < INF;
}

macro bool is_inf(FInt x)
{
	return abs(x) == INF;
}

macro bool is_nan(FInt x)
{
	return abs(x) > INF;
}

macro bool is_qnan(FInt x)
{
	return abs(x) >= QNAN;
}

macro bool is_snan(FInt x)
{
	return abs(x) - INF - 1u < QNAN - INF - 1u;
}

macro FInt get_payload(FInt x)
{
	return x & integer::const_bitmask(FInt, SIG_BITS - 1);
}






