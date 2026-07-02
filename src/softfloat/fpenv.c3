module radiance::softfloat;

// Interface fpenv
// fn void subnormal_inputs_enabled()
// fn void subnormal_outputs_enabled()

struct SoftFloatEnv
{
	SoftFloatExceptionMask  flags; 
	SoftFloatExceptionMask  exceptions;
	RadianceRoundingMode    rounding_mode;
	bool                    flush_subnormal_inputs;
	bool                    flush_subnormal_outputs;
	bool                    underflow_after_rounding;
}

enum SoftFloatException : char
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

bitstruct SoftFloatExceptionMask : char
{
	// IEEE754
	bool invalid;
	bool infinite;
	bool overflow;
	bool underflow;
	bool inexact;

	// NON-IEEE754
	bool subnormal;
}

alias SoftFloatExceptionHandler = fn void(SoftFloatExceptionMask);


fn bool SoftFloatExceptionMask.test(self, SoftFloatExceptionMask flags)
{
	return !!(self & flags);
}

fn SoftFloatExceptionMask SoftFloatEnv.save_flags(&self)
{
	return self.flags;
}

fn void SoftFloatEnv.restore_flags(&self, SoftFloatExceptionMask flags)
{
	self.flags = flags;
}

fn void SoftFloatEnv.raise_flags(&self, SoftFloatExceptionMask flags)
{
	self.flags |= flags;
}

fn void SoftFloatEnv.lower_flags(&self, SoftFloatExceptionMask flags)
{
	self.flags &= ~flags;
}

fn bool SoftFloatEnv.test_flags(&self, SoftFloatExceptionMask flags)
{
	return self.flags.test(flags);
}



tlocal SoftFloatEnv _env;

fn SoftFloatExceptionMask save_flags() => _env.save_flags();
fn void restore_flags(SoftFloatExceptionMask flags) => _env.restore_flags(flags);
fn void raise_flags(SoftFloatExceptionMask flags) => _env.raise_flags(flags);
fn void lower_flags(SoftFloatExceptionMask flags) => _env.lower_flags(flags);
fn bool test_flags(SoftFloatExceptionMask flags) => _env.test_flags(flags);





