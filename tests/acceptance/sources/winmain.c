/* tests/acceptance/sources/winmain.c - trivial windows entry point. */
#include <windows.h>

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrev, LPSTR lpCmd, int nShow)
{
	(void)hInstance;
	(void)hPrev;
	(void)lpCmd;
	(void)nShow;
	return 0;
}
