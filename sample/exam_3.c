#include <stdio.h>

typedef enum {
	E_A = 0,
	E_B,
} ENUM_TEST_A;

static ENUM_TEST_A (*pfunc[10])(ENUM_TEST_A*) = {
	NULL,
	NULL,
};

int main(void)
{
	pfunc();
	return 0;
}