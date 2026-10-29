module radiance::iefp;

struct IefpEnv
{
	IefpExceptionMask  flags;
	IefpExceptionMask  exceptions;
	IefpRoundingMode   rounding_mode;
	bool               flush_subnormal_inputs;
	bool               flush_subnormal_outputs;
	bool               underflow_after_rounding;
}

enum IefpException : int
{
	<*
		This exception is signaled when there is no meaningfully definable result
		for the operation. This includes operations that react to signaling NaN operands.
	*>
	INVALID,

	<*
		This exception is signaled whenever an exact infinite result is returned from
		an operation on finite operands.

		IEEE754 calls this the Divide By Zero exception.
	*>
	INFINITE,

	<*
		This exception is signaled when the rounded result, with an unbounded
		exponent range, is larger than the largest finite number. Or equivalently,
		when said result would have an exponent higher than the format's maximum exponent.
	*>
	OVERFLOW,

	<*
		This exception is allowed to be signaled either if the absolute value of the
		exact result is nonzero and less than the smallest normal number (underflow
		before rounding) *or* if the absolute value of the rounded result, with an
		unbounded exponent range, is less than smallest normal number (underflow
		after rounding).

		This ambiguity is only present for binary formats. For decimal formats,
		underflow is signaled after rounding.

		There are ways to configure which definition of underflow an operation will use.
	*>
	UNDERFLOW,

	<*
		This exception is signaled if the rounded result is different from the exact result.
	*>
	INEXACT,


	<*
		This exception is signaled if at least one operand is subnormal.

		This exception is not apart of IEEE754-2019, but exists in the AMD64 architecture.
	*>
	SUBNORMAL,

}

bitstruct IefpExceptionMask : char
{
	// ieee754-2019
	bool invalid;
	bool infinite;
	bool overflow;
	bool underflow;
	bool inexact;

	// non ieee754-2019
	bool subnormal;
}

alias IefpExceptionHandler = fn void(IefpExceptionMask);


fn bool IefpExceptionMask.test(self, IefpExceptionMask flags)
{
	return !!(self & flags);
}

fn IefpExceptionMask IefpEnv.save_flags(&self)
{
	return self.flags;
}

fn void IefpEnv.restore_flags(&self, IefpExceptionMask flags)
{
	self.flags = flags;
}

fn void IefpEnv.raise_flags(&self, IefpExceptionMask flags)
{
	self.flags |= flags;
}

fn void IefpEnv.lower_flags(&self, IefpExceptionMask flags)
{
	self.flags &= ~flags;
}

fn bool IefpEnv.test_flags(&self, IefpExceptionMask flags)
{
	return self.flags.test(flags);
}

tlocal IefpEnv _env;

fn IefpExceptionMask save_flags() => _env.save_flags();
fn void restore_flags(IefpExceptionMask flags) => _env.restore_flags(flags);
fn void raise_flags(IefpExceptionMask flags) => _env.raise_flags(flags);
fn void lower_flags(IefpExceptionMask flags) => _env.lower_flags(flags);
fn bool test_flags(IefpExceptionMask flags) => _env.test_flags(flags);

