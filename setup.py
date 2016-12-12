#!/usr/bin/env python

"Minimal cython extension module build script"

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

# Feel free to add many pyx or py files in this list, even C files...
ext_modules = [Extension("hello", ["hello.pyx"])]

setup(
  name = 'Hello world',
  cmdclass = {'build_ext': build_ext},
  ext_modules = ext_modules
)
