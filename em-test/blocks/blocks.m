#include <stdio.h>

typedef void (^blk_t)(int);

int main()
{
	int x = 1;
	blk_t b = ^(int y){
		printf("%d", x + y);
	};
	b(2);
}
