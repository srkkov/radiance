module radiance::flt::binary <WIDTH, PRECISION>;
import radiance::integer;

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
