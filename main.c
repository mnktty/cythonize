#include <Python.h>
#include "hello.h"

int main(int argc, char *argv[])
{
    /* Boilter plate code required to initialize and finalize python runtime */
                      
    Py_SetProgramName(argv[0]);
    Py_Initialize();

    /* init module and call c wrapper function */
    inithello();
    int i;
    for (i = 1; i < argc; ++i)
    {
        c_say_hello_to(argv[i]);
    }
    
    Py_Finalize();
    return 0;
}

