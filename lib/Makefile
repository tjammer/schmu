##
# Compile llvm byval stub
#
# @file
# @version 0.1

.PHONY: all clean

all: dllbyval.so libbyval.a

# we need different flags on macos
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    SOFLAGS += -undefined dynamic_lookup
endif

dllbyval.so: byval.o
	${CC} -shared -o dllbyval.so byval.o $(SOFLAGS)

libbyval.a: byval.o
	${AR} rvs libbyval.a byval.o

byval.o: byval.cpp configure.sh
	${CXX} $(shell bash configure.sh 19) -I$(shell opam var ocaml:lib) -fPIC -c byval.cpp

clean:
	rm byval.o libbyval.a dllbyval.so

# end
