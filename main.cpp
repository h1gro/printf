#include <stdio.h>
#include <stdlib.h>

extern "C" int my_printf(const char*, ...);

int main()
{
    const char* string1 = "HAHAh$";
    const char* string2 = "slut";
    //my_printf("%d %d %d %d \n%d %d %d %d \n%d %d %d %d %d\n%%%%%%%%%%%%%%%%%%$", 1154436, 22235426, 3334646, 448966, 55976, 7697966, 775558, 375388, 993222, 143630, 165471, 127547, 137444);
    my_printf("%d$", 153);
    printf("обычный принт\n");
    //exit(0);
    //return 0;
}
