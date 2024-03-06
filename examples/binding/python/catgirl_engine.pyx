# cython: language_level=3
# distutils: libraries = main
# distutils: library_dirs = ../../../target/release
# distutils: include_dirs = ../../../target/binding

from libc.stdlib cimport malloc, free

# Import catgirl_engine.pxd
cimport catgirl_engine


def run(args: list):
    cdef const char** c_args
    c_args = <const char**> malloc(sizeof(const char*)*len(args))

    try:
        for n, a in enumerate(args):
            c_args[n] = a

        return catgirl_engine.ce_start(len(args), c_args)
    finally:
        free(c_args)
