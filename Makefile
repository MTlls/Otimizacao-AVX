# PROGRAMA
        PROG = matmult
        OBJS = $(PROG).o matriz.o utils.o

# Compilador
	CC = gcc -Wall
	override CFLAGS += -Wall -O3 -mavx -march=native -I${LIKWID_HOME}/include
	LFLAGS = -lm -L${LIKWID_HOME}/lib -llikwid

# Lista de arquivos para distribuição
DISTFILES = *.c *.h README.md Makefile perfctr
DISTDIR = `basename ${PWD}`

.PHONY: all debug clean purge dist otimiza

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $<

all: $(PROG)

debug: CFLAGS += -g -D_DEBUG_
debug: all

otimiza: CFLAGS += -D_O_
otimiza: all

$(PROG): $(OBJS) 
	$(CC) $(CFLAGS) -o $@ $^ $(LFLAGS)

clean:
	@echo "Limpando ...."
	@rm -f *~ *.bak *.tmp core 

purge: clean
	@echo "Faxina ...."
	@rm -f  $(PROG) *.o *.out a.out $(DISTDIR) $(DISTDIR).tar
	@rm -f *.png marker.out

dist: purge
	@echo "Gerando arquivo de distribuição ($(DISTDIR).tar) ..."
	@ln -s . $(DISTDIR)
	@tar -cvf $(DISTDIR).tar $(addprefix ./$(DISTDIR)/, $(DISTFILES))
	@rm -f $(DISTDIR)

