module radiance::softfloat::binary <WIDTH, PRECISION>;
import radiance::integer;
import std::io;

macro FInt const_bitmask(int $width) => integer::const_bitmask(FInt, $width);

alias FInt = integer::unsigned_from_bitsize(WIDTH);

const int K   @private = WIDTH;
const int KM1 @private = K - 1;
const int KM2 @private = K - 2;
const int P   @private = PRECISION;
const int PM1 @private = P - 1;
const int PM2 @private = P - 2;
const FInt BIT_PM1 @private = (FInt)1 << PM1;
const FInt BIT_PM2 @private = (FInt)1 << PM2;
const FInt BIT_KM1 @private = (FInt)1 << KM1;

const int EXP_BITS  = WIDTH - PRECISION;
const int FRAC_BITS = PRECISION - 1;
const int EXP_MAX   = (1 << (EXP_BITS - 1)) - 1;
const int EXP_MIN   = 1 - EXP_MAX;
const int BIAS      = EXP_MAX;

const FInt SIGN_MASK = BIT_KM1;
const FInt FRAC_MASK = const_bitmask(FRAC_BITS);

const FInt INF = BIT_KM1 - BIT_PM1;
const FInt QNAN = BIT_KM1 - BIT_PM2;

const FInt MIN_SUBNORMAL = 1;
const FInt MAX_SUBNORMAL = BIT_PM1 - 1;
const FInt MIN_NORMAL = BIT_PM1;
const FInt MAX_NORMAL = BIT_KM1 - BIT_PM1 - 1;

macro FInt abs(FInt x) => x & ~SIGN_MASK;

macro bool sign(FInt x) => !!(x & SIGN_MASK);

<* @require !sign(x) *>
macro bool is_zero_abs(FInt x) => !x;

<* @require !sign(x) *>
macro bool is_subnormal_abs(FInt x) => 0 < x && x < BIT_PM1;

<* @require !sign(x) *>
macro bool is_normal_abs(FInt x) => BIT_PM1 <= x && x < BIT_KM1 - BIT_PM1;

<* @require !sign(x) *>
macro bool is_finite_abs(FInt x) => x < INF;

<* @require !sign(x) *>
macro bool is_regular_abs(FInt x) => 0 < x && x < INF;

<* @require !sign(x) *>
macro bool is_inf_abs(FInt x) => x == INF;

<* @require !sign(x) *>
macro bool is_nan_abs(FInt x) => x > INF;

<* @require !sign(x) *>
macro bool is_snan_abs(FInt x) => INF < x && x < QNAN;

<* @require !sign(x) *>
macro bool is_qnan_abs(FInt x) => x >= QNAN;

macro bool is_zero       (FInt x) => is_zero_abs       (abs(x));
macro bool is_subnormal  (FInt x) => is_subnormal_abs  (abs(x));
macro bool is_normal     (FInt x) => is_normal_abs     (abs(x));
macro bool is_finite     (FInt x) => is_finite_abs     (abs(x));
macro bool is_regular    (FInt x) => is_regular_abs    (abs(x));
macro bool is_inf        (FInt x) => is_inf_abs        (abs(x));
macro bool is_nan        (FInt x) => is_nan_abs        (abs(x));
macro bool is_snan       (FInt x) => is_snan_abs       (abs(x));
macro bool is_qnan       (FInt x) => is_qnan_abs       (abs(x));

<*
 @require is_nan(x)
*>
macro bool is_signalling(FInt x)
{
	return x < QNAN;
}

<*
 @require is_nan(x)
*>
macro FInt get_payload(FInt x)
{
	return x & const_bitmask(FRAC_BITS - 2);
}






