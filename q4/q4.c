#include <stdio.h>
#include <dlfcn.h>
int main ()
{

    char str[6], lib[13] ;
    int a, b ;
    while(scanf("%s %d %d", str, &a, &b) == 3) 
    {

        snprintf(lib, sizeof(lib), "./lib%s.so", str) ; // adding ./ because C is retarded and will go to /usr/lib if i dont
        void *handle = dlopen(lib, RTLD_LAZY) ;
        if (!handle) 
        {
            fprintf(stderr, "%s\n", dlerror()) ;
            continue ;
        }
        
        void *p = dlsym(handle, str) ; // getting the address of the function from the library
        int (*fun)(int, int) ; // initialising function pointer which gives out int after taking 2 int
        fun = (int (*)(int, int))p ; // storing the function in fun

        int ans = fun(a, b) ;
        printf("%d\n", ans) ;
        dlclose(handle) ;
    }   
    return 0 ;
}