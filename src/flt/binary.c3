module radiance::flt::binary <WIDTH, PRECISION>;
import radiance::integer;

macro FInt _abs(FInt x) @private => x & ~SIGN_MASK;
macro bool _sign(FInt x) @private => !!(x & SIGN_MASK);

macro FInt @mask(int $width) => bit::@mask{FInt}($width);

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
const FInt FRAC_MASK = @mask(FRAC_BITS);

const FInt INF = BIT_KM1 - BIT_PM1;
const FInt QNAN = BIT_KM1 - BIT_PM2;

const FInt MIN_SUBNORMAL = 1;
const FInt MAX_SUBNORMAL = BIT_PM1 - 1;
const FInt MIN_NORMAL = BIT_PM1;
const FInt MAX_NORMAL = BIT_KM1 - BIT_PM1 - 1;

// <*
//  @require is_nan(x)
// *>
// macro FInt get_payload(FInt x)
// {
// 	return x & const_bitmask(FRAC_BITS - 1);
// }



