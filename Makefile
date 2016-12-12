# Makefile for Linux

CC=gcc
INCLUDE=-I /usr/include/python2.6 
LIBS = -lpython2.6

packed:
	gcc -c $(INCLUDE) main.c 
	gcc -o cwrapped main.o $(LIBS) ./hello.so -Wl,-soname,hello.so hello.so

# if libhello.so existed, call the following command
# gcc -o cwrapped -I /usr/include/python2.6 main.c -L./ -lhello -lpython2.6

.PHONY=clean

clean:
	rm cwrapped


#eof