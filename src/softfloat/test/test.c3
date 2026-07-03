module radiance::softfloat::test @if(env::TESTING);
import std::io;

ulong total_checks;

fn void more_stats() @finalizer
{
	io::printfn("total checks: %d", total_checks);
}

const bool LONG_TEST = $feature(LONG_TEST);


