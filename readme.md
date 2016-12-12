# Motivation

Developing application programs in Python is a far faster and better experience
compared any of the compiled languages such as C. However, under certain
conditions, it becomes imperative to ship binaries in native format. This
cookbook describes how to achieve this with existing python implemntations,
especially exporting pure C interfaces which can be called from C programs. The
key idea is to build a python extension module with a C interface so that the
functions can be called from python as well as C.

# Pre-requisite

-   Cython: <http://cython.org> - the Python to C compiler
-   Your native compiler. e.g. gcc/Linux, mingw32/Windows

# Linux

Consider the following python function:

    __file__ = 'hello.pyx' # implement a cython based python extension module
    
      def say_hello_to(name):
          print ('Say Hello to %s !' )

If we cythonize this implementation and build an extension module `hello`,
python can call the function, for example, as:

    import hello
    for name in ('Alice', 'Bob', 'John'):
        hello.say_hello_to(name)

However, it is not possible for C functions to do the same. The trick is to
define a wrapper C interface as follows:

    cdef public void c_say_hello_to(char *name):
        """C interface exposed through cython
        """
        say_hello_to(name)

The basic setup script would look as follows:

    "Minimal cython extension module build script"
    
    from distutils.core import setup
    from distutils.extension import Extension
    from Cython.Distutils import build_ext
    
    ext_modules = [Extension("hello", ["hello.pyx"])] # add more .pyx or .c files here
    
    setup(
      name = 'Hello world app',
      cmdclass = {'build_ext': build_ext},
      ext_modules = ext_modules
    )

Build the cython extension to generate `hello.so` and calling
`hello.say_hello_to()` should work as expected.

    python setup.py build_ext --inplace

And the the C wrapper function can be called in C code as follows:

    /* implemented in main.c */
    
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

Build instructions for this executable would be:

    gcc -o cwrapped -I /usr/include/python2.6 main.c -L./ -lhello -lpython2.6

**Caveat**: Building the extension module produces `hello.so` and not
`libhello.so`. There are two solutions:

1.  Make a softlink or copy of `hello.so` as `libhello.so`. Do not forget to
    set `LD_LIBRARY_PATH` to include directory containing `libhello.so` in
    this case. See Appendix for details.

2.  Tell gcc explicitly to link against `hello.so` using a linker
    directive. This is possible only on ELF systems like Linux. In this case

    gcc -c -I /usr/include/python2.6 main.c 
    gcc -o cwrapped main.o -lpython2.6 ./hello.so -Wl,-soname,hello.so hello.so

Now you should be able to call the binary as follows:

    $ ./cwrapped Alice Bob John
    Say Hello to Alice!
    Say Hello to Bob!
    Say Hello to John!

# Windows

This section describes creating the binaries with mingw32. By default, windows
binaries expect Microsoft compiler.

## Patch this first !

### Mingw32 and Distutils of Python 2.7

The compiler script for mingw32 is broken. Please make the following edits in
`distutils/cygwinccompiler.py` for class `Mingw32CCompiler`

-   Remove any instances of `-mno-cygwin`. This switch is deprecated in
    mingw32, but python has not yet edited this out !

-   `self.dll_libraries` should not include any `msvcrxx.dll` - comment the
    call to `get_msvcr()`. This ensures that Microsoft C runtime libs
    (e.g. `msvcr90.dll`) are not linked against the executable un-necessarily

### DLL export of Cython C functions

In order to do a DLL export of the C(ython) function, use the keyword
`api`. Using only `api` and importing the module does not work in Linux as
described in Cython documentation - it gave a segfault.

    cdef public api void c_say_hello_to(char *name): # note keyword api
        """C interface exposed through cython
        """
        say_hello_to(name)

## Build

The cythonizing steps are the same, except that the output is `hello.pxd`, which
is identical to a DLL. This can be used as-is by Python. See python
documentation on why `.pxd` is used as an extension module name. Do not forget
to specify the compiler if you are using mingw32.

    python setup.py build_ext --inplace --compiler=mingw32

For more options for building extension modules, try `python setup.py build_ext
--help`

To link the main program, the following compilation steps are needed, very much
like in Linux. Note that gcc is from mingw32.

    gcc -c -I /c/Programs/Python27/include main.c 
    gcc -o cwrapped.exe main.o -L /c/Programs/Python27/libs -lpython27 ./hello.pyd -Wl,-soname,hello.pyd hello.pyd

# Appendix

## Cython installation

Cython is available as a package for Linux (e.g. Ubuntu). If not, install cython
after building with `setup.py`. For Windows, specify the compiler if it is not
Microsoft VC++, as follows:

    python setup.py install build --compiler=mingw32

## Setting `LD_LIBRARY_PATH`

For quick checks in the shell, do:

    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:`pwd`

# References

1.  Cython Documentation, esp. Building Extension Modules, Using Cython Declarations from C
2.  Python Documentation, esp. Embedding Python in C and C++
3.  <http://stackoverflow.com/questions/5710441/call-cython-function-from-c>
4.  <http://stackoverflow.com/questions/1305266/how-to-link-to-a-shared-library-without-lib-prefix-in-a-different-directory>
5.  <http://www.transmissionzero.co.uk/computing/building-dlls-with-mingw/>
6.  <http://stackoverflow.com/questions/6034390/compiling-with-cython-and-mingw-produces-gcc-error-unrecognized-command-line-o>
7.  <http://code.activestate.com/lists/python-distutils-sig/18200/>
