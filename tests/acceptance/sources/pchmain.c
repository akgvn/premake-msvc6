/* tests/acceptance/sources/pchmain.c - uses the precompiled header. */
#include "accept.h"

int main(void)
{
	return pch_ready() - 1;
}
