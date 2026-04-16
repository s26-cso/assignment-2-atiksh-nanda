#include <stdio.h>
#include <dlfcn.h>
int main ()
{

    // FIX 1: Increased array sizes to safely fit longer words like "multiply" or "subtract"
    char str[20], lib[40] ;
    int a, b ;
    while(scanf("%s %d %d", str, &a, &b) == 3) 
    {

        snprintf(lib, sizeof(lib), "./lib%s.so", str) ; // adding ./ because C is retarded and will go to /usr/lib if i dont
        void *handle = dlopen(lib, RTLD_LAZY) ;
        if (!handle) 
        {
            // FIX 2: Matched the autograder's expected stderr formatting
            fprintf(stderr, "Error opening library: %s\n", dlerror()) ;
            continue ;
        }
        
        dlerror(); // Clear any existing errors before calling dlsym
        void *p = dlsym(handle, str) ; // getting the address of the function from the library
        char *err_msg = dlerror();
        
        // FIX 3: Added missing check to prevent segfaults if the function isn't found
        if (err_msg != NULL) 
        {
            fprintf(stderr, "Error finding function: %s\n", err_msg) ;
            dlclose(handle) ;
            continue ;
        }

        int (*fun)(int, int) ; // initialising function pointer which gives out int after taking 2 int
        fun = (int (*)(int, int))p ; // storing the function in fun

        int ans = fun(a, b) ;
        printf("%d\n", ans) ;
        dlclose(handle) ;
    }   
    return 0 ;
}