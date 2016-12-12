"""Extension module with python and C interfaces. Needs cython to compile and
use."""

def say_hello_to(name):
    """Pure python function, will be available to python scripts using this
    extension module"""
    print("Say Hello to %s!" % name)


cdef public api void c_say_hello_to(char *name):
    """C interface exposed through cython
    """
    say_hello_to(name)

# eof
