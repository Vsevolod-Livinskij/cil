# toplevel Makefile for cil project
# author: George Necula
#
# 3/06/01 sm: made the rules depend on environment variable ARCHOS,
#             so I can say x86_LINUX
# 3/17/01 sm: replaced a few more instances of x86_WIN32 with $(ARCHOS)

# Debugging. Set ECHO= to debug this Makefile 
ECHO = @

# USECCGR = 1
USEFRONTC = 1

# First stuff that makes the executable 
# Define the ARCHOS in your environemt : [x86_LINUX, x86_WIN32, SUNOS]

SOURCEDIRS  = src
OBJDIR      = obj
MLLS        = 
MLYS        = 
# ast clex cparse
# sm: trace: utility for debug-time printfs
MODULES     = pretty trace errormsg stats cil check ptrnode \
              simplesolve markptr box optim
EXECUTABLE  = $(OBJDIR)/safec
CAMLUSEUNIX = 1
ifdef RELEASE
UNSAFE      = 1
endif
CAMLLIBS    = 

ifdef USECCGR
MLLS      += mllex.mll
MLYS      += cilparse.mly
MODULES   += mllex cilparse
PARSELIBS += ../parsgen/libccgr.a ../smbase/libsmbase.a \
             libstdc++-3-libc6.1-2-2.10.0.a
endif

ifdef USEFRONTC
SOURCEDIRS += src/frontc
MLLS       += clexer.mll
MLYS       += cparser.mly
MODULES    += cabs clexer cparser cprint cabs2cil frontc
endif

# Add main late
MODULES    += combine main
    # Include now the common set of rules for OCAML
    # This file will add the rules to make $(EXECUTABLE).$(EXE)
include Makefile.ocaml




##### Settings that depend on the computer we are on
##### Make sure the COMPUTERNAME environment variable is set
ifeq ($(COMPUTERNAME), RAW)   # George's workstation
BASEDIR=C:/Necula
TVDIR=$(BASEDIR)/Source/TransVal
CILDIR=$(SAFECCDIR)/cil
SAFECCDIR=$(BASEDIR)/SafeC
PCCDIR=$(SAFECCDIR)/cil/test/PCC
endif
ifeq ($(COMPUTERNAME), FETA) # George's home machine
BASEDIR=C:/Necula
TVDIR=$(BASEDIR)/Source/TransVal
CILDIR=$(SAFECCDIR)/cil
SAFECCDIR=$(BASEDIR)/SafeC
PCCDIR=$(SAFECCDIR)/cil/test/PCC
endif
ifeq ($(COMPUTERNAME), tenshi) # Wes's laptop
BASEDIR=/home/weimer/cvs/
SAFECCDIR=$(BASEDIR)/safeC
PCCDIR=$(BASEDIR)/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif
ifeq ($(COMPUTERNAME), madrone) # scott's desktop
BASEDIR=/home/scott/wrk/safec
SAFECCDIR=$(BASEDIR)
PCCDIR=$(SAFECCDIR)/cil/test/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif
ifeq ($(COMPUTERNAME), leetch) # scott's laptop
BASEDIR=/home/scott/wrk/safec
SAFECCDIR=$(BASEDIR)
PCCDIR=$(SAFECCDIR)/cil/test/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif
ifeq ($(COMPUTERNAME), fuji) # Rahul's laptop
BASEDIR=/home/sprahul/research
SAFECCDIR=$(BASEDIR)
PCCDIR=$(BASEDIR)/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif
ifeq ($(COMPUTERNAME), brooksie) # Rahul's desktop
BASEDIR=/home/sprahul/research
SAFECCDIR=$(BASEDIR)
PCCDIR=$(BASEDIR)/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif
ifeq ($(COMPUTERNAME), brooksie_george) # Rahul's desktop, for George
BASEDIR=/home/necula/Source
SAFECCDIR=$(BASEDIR)
PCCDIR=$(SAFECCDIR)/cil/test/PCC
TVDIR=$(BASEDIR)/TransVal
CILDIR=$(BASEDIR)/cil
_GNUCC=1
endif

# sm: I keep getting bit by this
ifndef COMPUTERNAME
# sm: why doesn't this do what the manual says?
#HMM=$(error "wtf")
HMM="you_have_to_set_the_COMPUTERNAME_environment_variable"
BASEDIR=$(HMM)
SAFECCDIR=$(HMM)
PCCDIR=$(HMM)
TVDIR=$(HMM)
CILDIR=$(HMM)
_GNUCC=$(HMM)
endif


######################
.PHONY : spec
spec : $(EXECUTABLE)$(EXE)

.PHONY: trval
trval: $(TVDIR)/obj/transval.asm.exe
	make -C $(TVDIR) RELEASE=1

export EXTRAARGS
export BOX
ifndef _GNUCC
_MSVC = 1			# Use the MSVC compiler by default
endif

ifdef _GNUCC
DEBUGCCL=gcc -x c -O0 -g -D_GNUCC 
RELEASECCL=gcc -x c -O3 -Wall -I/usr/include/sys
#LIB=lib
#LIBOUT=-o
DOOPT=-O3
CONLY=-c
OBJOUT=-o
EXEOUT=-o
DEF=-D
ASMONLY=-S -o 
CPPSTART=gcc -E %i -Dx86_LINUX -D_GNUCC  -I/usr/include/sys
CPPOUT=-o %o
CPP=$(CPPSTART) $(CPPOUT)
INC=-I
PATCHFILE=safec_gcc.patch
# sm: disable patching for now ('true' has no output)
PATCHECHO=true
endif


ifdef _MSVC
DEBUGCCL=cl /TC /O0 /Zi /MLd /I./lib /DEBUG
RELEASECCL=cl /TC /ML /I./lib
ifdef RELEASE
DOOPT=/Ox /Ob2
else
DOOPT=
endif
CONLY=/c
OBJOUT=/Fo
EXEOUT=/Fe
DEF=/D
ASMONLY=/Fa
INC=/I
CPPSTART=cl /Dx86_WIN32 /D_MSVC /E /TC /I./lib /FI fixup.h /DBEFOREBOX
CPPOUT= %i >%o
CPP=$(CPPSTART) $(CPPOUT)
EXTRAARGS += --safec=-msvc
PATCHFILE=safec_msvc.patch
PATCHECHO=echo
endif

ifdef RELEASE
CCL=$(RELEASECCL)
else
CCL=$(DEBUGCCL)
endif
CC=$(CCL) $(CONLY)


SAFECC=perl $(CILDIR)/lib/safecc.pl
ifndef NOCABS
SAFECC+= --cabs
endif
ifndef NOCIL
SAFECC+= --cil
endif	
ifdef BOX
SAFECC+= --box
endif
ifdef INFERBOX
SAFECC+= --inferbox
else
ifndef MANUALBOX
SAFECC+= --safec=-boxdefaultwild
endif
endif
ifdef MANUALBOX
EXTRAARGS+= $(DEF)MANUALBOX
endif
ifdef NO_TAGS
SAFECC+= $(DEF)NO_TAGS
endif
ifdef CHECK
EXTRAARGS += --safec=-check
endif
ifdef RELEASE
SAFECC+= --release
endif
ifdef TV
SAFECC+= --tv="$(TV)"
TVEXE=trval
endif
# sm: pass tracing directives on 'make' command line like TRACE=usedVars
ifdef TRACE
SAFECC+= --tr="$(TRACE)"
endif

ifdef OPTIM
SAFECC += --optim
endif

SAFECC+= $(EXTRAARGS)

    # Now the rules to make the library
ifdef _MSVC
ifdef RELEASE
SAFECLIB=/Necula/SafeC/cil/obj/safec.lib
else
SAFECLIB=/Necula/SafeC/cil/obj/safecdebug.lib
SAFECLIBARG=$(DEF)_DEBUG
endif
$(SAFECLIB) : $(SAFECCDIR)/cil/lib/safec.c \
              $(SAFECCDIR)/cil/lib/safec.h \
              $(SAFECCDIR)/cil/lib/safeccheck.h
	cl /Ox /Zi /I./lib /c $(DEF)_MSVC $(SAFECLIBARG) \
                                          $(OBJOUT)$(OBJDIR)/safec.o $<
	lib /OUT:$(SAFECLIB) $(OBJDIR)/safec.o 

SAFEMAINLIB=/Necula/SafeC/cil/obj/safecmain.lib
$(SAFEMAINLIB) : $(SAFECCDIR)/cil/lib/safecmain.c \
                 $(SAFECCDIR)/cil/lib/safec.h \
                 $(SAFECCDIR)/cil/lib/safeccheck.h
	cl /Ox /Zi /I./lib /c $(DEF)_MSVC $(OBJOUT)$(OBJDIR)/safecmain.o $<
	lib /OUT:$(SAFEMAINLIB) $(OBJDIR)/safecmain.o 
endif
ifdef _GNUCC
ifdef RELEASE
SAFECLIB=$(OBJDIR)/safeclib.a
else
SAFECLIB=$(OBJDIR)/safecdebuglib.a
endif
$(SAFECLIB) : $(SAFECCDIR)/cil/lib/safec.c
	$(CC) $(OBJOUT)$(OBJDIR)/safec.o $<
	ar -r $(SAFECLIB) $(OBJDIR)/safec.o
SAFEMAINLIB=$(OBJDIR)/safecmain.a
$(SAFEMAINLIB) : $(SAFECCDIR)/cil/lib/safecmain.c \
                 $(SAFECCDIR)/cil/lib/safec.h \
                 $(SAFECCDIR)/cil/lib/safeccheck.h
	$(CC) $(OBJOUT)$(OBJDIR)/safecmain.o $<
	ar -r $(SAFEMAINLIB) $(OBJDIR)/safecmain.o
endif


####### Test with PCC sources
PCCTEST=test/PCCout
ifdef RELEASE
PCCTYPE=RELEASE
SPJARG=
else
PCCTYPE=_DEBUG
SPJARG=--gory --save-temps=pccout
endif
ifdef _GNUCC
PCCCOMP=_GNUCC
else
PCCCOMP=_MSVC
endif

testpcc/% : $(PCCDIR)/src/%.c $(EXECUTABLE)$(EXE) $(TVEXE)
	cd $(SAFECCDIR)/cil/test/PCCout; $(SAFECC) --keep=. $(DEF)$(ARCHOS) \
                  $(DEF)$(PCCTYPE) $(CONLY) \
                  $(PCCDIR)/src/$*.c \
                  $(OBJOUT)$(notdir $*).o

testallpcc: $(EXECUTABLE)$(EXE) $(TVEXE) $(SAFECLIB) $(SAFEMAINLIB) 
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.o
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.exe
	make -C $(PCCDIR) \
             CC="$(SAFECC) --keep=$(CILDIR)/test/PCCout $(CONLY)" \
             USE_JAVA= USE_JUMPTABLE= TYPE=$(PCCTYPE) \
             COMPILER=$(PCCCOMP) \
             ENGINE_OTHERS="C:$(SAFECLIB) C:$(SAFEMAINLIB)" \
             TRANSLF_OTHERS="C:$(SAFECLIB) C:$(SAFEMAINLIB)" \
	     defaulttarget 

testallspj: $(EXECUTABLE)$(EXE) $(TVEXE) $(SAFECLIB) $(SAFEMAINLIB) 
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.o
	-rm $(PCCDIR)/x86_WIN32$(PCCCOMP)/$(PCCTYPE)/*.exe
	make -C $(PCCDIR) \
             CC="$(SAFECC) --keep=$(CILDIR)/test/PCCout $(CONLY)" \
             USE_JAVA=1 USE_JUMPTABLE=1 TYPE=$(PCCTYPE) \
             COMPILER=$(PCCCOMP) \
             ENGINE_OTHERS="C:$(SAFECLIB) C:$(SAFEMAINLIB)" \
             TRANSLF_OTHERS="C:$(SAFECLIB) C:$(SAFEMAINLIB)" \
	     defaulttarget 

runpcc:
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(PCCDIR)/test; test.cmd fact --save-temps=pccout --gory


SPJDIR=C:/Necula/Source/Touchstone/test
SPJARG +=  -WV,"-H,4000000,-noindent" -WC,"-H,4000000,-noindent"
ifndef RELEASE
SPJARG += --pccdebug
endif
ifdef SPJTIME
SPJARG += -WC,"-T,1000" 
endif

runspj.fact :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj Arith/Fact.java --gory $(SPJARG) --pcchome=$(PCCDIR)

runspj.linpack :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj linpack/Linpack.java --gory  \
                      $(SPJARG) --pcchome=$(PCCDIR)

runspj.quicksort :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj arrays/QuickSort.java --gory \
                      $(SPJARG) --pcchome=$(PCCDIR)

runspj.simplex :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj simplex/Simplex.java --gory  \
                      $(SPJARG) --pcchome=$(PCCDIR)

runspj.getopt :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj gnu/getopt --gory  \
                      $(SPJARG) --pcchome=$(PCCDIR)

runspj.antlr :
ifdef _GNUCC
	rm $(PCCDIR)/bin/*_MSVC*
endif
	cd $(SPJDIR); spj antlr --gory  "-WV,-H,10000000" "-WC,-H,10000000" \
                      $(SPJARG) --pcchome=$(PCCDIR)

############ Small tests
SMALL1=test/small1
test/% : $(SMALL1)/%.c $(EXECUTABLE)$(EXE) $(TVEXE)
	cd $(SMALL1); $(SAFECC)   \
               --patch=../../lib/$(PATCHFILE) \
	       $*.c $(CONLY) $(DOOPT) $(ASMONLY)$*.s

SMALL2=test/small2

hashtest: test/small2/hashtest.c $(EXECUTABLE)$(EXE) \
                                 $(SAFECLIB) $(SAFEMAINLIB)  $(TVEXE)
	rm -f $(PCCTEST)/hashtest.exe
	cd $(PCCTEST); $(SAFECC) --keep=. $(DEF)$(ARCHOS) $(DEF)$(PCCTYPE) \
                 $(DOOPT) \
                 `$(PATCHECHO) --patch=../../lib/$(PATCHFILE)` \
                 $(INC)$(PCCDIR)/src \
                 $(PCCDIR)/src/hash.c \
                 ../small2/hashtest.c \
                 $(EXEOUT)hashtest.exe
	$(PCCTEST)/hashtest.exe

rbtest: test/small2/rbtest.c $(EXECUTABLE)$(EXE) \
                                 $(SAFECLIB) $(SAFEMAINLIB)  $(TVEXE)
	rm -f $(PCCTEST)/rbtest.exe
	cd $(PCCTEST); $(SAFECC) --keep=. $(DEF)$(ARCHOS) $(DEF)$(PCCTYPE) \
                 `$(PATCHECHO) --patch=../../lib/$(PATCHFILE)` \
                 $(DOOPT) \
                 $(INC)$(PCCDIR)/src \
                 $(PCCDIR)/src/redblack.c \
                 ../small2/rbtest.c \
                 $(EXEOUT)rbtest.exe
	$(PCCTEST)/rbtest.exe

btreetest: test/small2/testbtree.c \
           test/small2/btree.c \
                                 $(EXECUTABLE)$(EXE) \
                                 $(SAFECLIB) $(SAFEMAINLIB)  $(TVEXE)
	rm -f test/small2/btreetest.exe
	cd test/small2; $(SAFECC) --keep=. \
                 $(DOOPT) \
                 --patch=../../lib/$(PATCHFILE) \
                 btree.c testbtree.c \
                 $(EXEOUT)btreetest.exe
	test/small2/btreetest.exe


# sm: this is my little test program
hola: test/small2/hola.c $(EXECUTABLE)$(EXE) \
                                 $(SAFECLIB) $(SAFEMAINLIB)
	rm -f test/small2/hola
	cd test/small2; $(SAFECC) --keep=. $(DEF)$(ARCHOS) \
                 `$(PATCHECHO) --patch=../../lib/$(PATCHFILE)` \
                 $(DOOPT) \
                 hola.c \
                 $(EXEOUT)hola
	test/small2/hola


HUFFCOMPILE=$(SAFECC) --keep=. 
# HUFFCOMPILE=cl /MLd
ifdef BOX
HUFFOTHERS="C:$(SAFEMAINLIB)" 
else
HUFFOTHERS=
endif
hufftest: test/small2/hufftest.c $(EXECUTABLE)$(EXE) \
                                 $(SAFECLIB) $(SAFEMAINLIB) $(TVEXE)
	rm -f $(PCCTEST)/hufftest.exe
	cd $(PCCTEST); $(HUFFCOMPILE) \
                 $(DEF)$(ARCHOS) $(DEF)$(PCCTYPE) $(DEF)$(PCCCOMP) \
                 $(DOOPT) \
                 --patch=../../lib/$(PATCHFILE) \
                 $(INC)$(PCCDIR)/src \
                 $(PCCDIR)/src/io.c \
                 $(PCCDIR)/src/huffman.c \
                 $(PCCDIR)/src/hash.c \
                 ../small2/hufftest.c \
                 $(HUFFOTHERS) \
                 $(EXEOUT)hufftest.exe
	cd $(PCCTEST); ./hufftest.exe \
                             $(SAFECCDIR)/cil/src/frontc/cparser.output

wes-rbtest: test/small2/wes-rbtest.c $(EXECUTABLE)$(EXE) $(TVEXE)\
            $(SAFECLIB)
	rm -f $(PCCTEST)/wes-rbtest.exe
	cd $(PCCTEST); $(SAFECC) --keep=. $(DEF)$(ARCHOS) $(DEF)$(PCCTYPE) \
                 $(DOOPT) \
                 --patch=../../lib/$(PATCHFILE) \
                 $(INC)$(PCCDIR)/src \
                 ../small2/wes-rbtest.c \
                 $(EXEOUT)wes-rbtest.exe
	$(PCCTEST)/wes-rbtest.exe

wes-hashtest: test/small2/wes-hashtest.c $(EXECUTABLE)$(EXE) $(TVEXE) \
              $(SAFECLIB)
	rm -f $(PCCTEST)/wes-hashtest.exe
	cd $(PCCTEST); $(SAFECC) --keep=. $(DEF)$(ARCHOS) $(DEF)$(PCCTYPE) \
                 $(DOOPT) \
                 --patch=../../lib/$(PATCHFILE) \
                 $(INC)$(PCCDIR)/src \
                 ../small2/wes-hashtest.c \
                 $(EXEOUT)wes-hashtest.exe
	$(PCCTEST)/wes-hashtest.exe


### Generic test
testfile/% : $(EXECUTABLE)$(EXE) %  $(TVEXE)
	$(SAFECC) /TC $*

testdir/% : $(EXECUTABLE)$(EXE)
	make -C CC="perl safecc.pl" $*


################## Linux device drivers
testlinux/% : $(EXECUTABLE)$(EXE) test/linux/%.cpp
	cd test/linux; $(SAFECC) -o $*.o $*.cpp 

testqp : testlinux/qpmouse
testserial: testlinux/generic_serial

################## Rahul's test cases
SPR-TESTDIR = test/spr
spr/% : $(EXECUTABLE)$(EXE)
	cd $(SPR-TESTDIR); $(SAFECC) $*.c $(CONLY) $(DOOPT) $(ASMONLY)$*.s


################# Apache test cases
APACHETEST=test/apache
APACHEBASE=apache_1.3.19/src
ifdef _MSVC
APACHECFLAGS=/nologo /MDd /W3 /GX /Zi /Od \
         $(INC)"$(APACHEBASE)\include" $(INC)"$(APACHEBASE)\os\win32" \
         $(DEF)"_DEBUG" $(DEF)"WIN32" $(DEF)"_WINDOWS" \
         $(DEF)"NO_DBM_REWRITEMAP" $(DEF)"SHARED_MODULE" \
         $(DEF)"WIN32_LEAN_AND_MEAN"
APATCH=--patch=apache_msvc.patch
else
APACHECFLAGS=-Wall -D_GNUCC -g \
         $(INC)"$(APACHEBASE)/include" $(INC)"$(APACHEBASE)/os/unix" \
         $(DEF)"_DEBUG" \
         $(DEF)"NO_DBM_REWRITEMAP" $(DEF)"SHARED_MODULE"
APATCH=--patch=apache_gcc.patch
endif

apache/gzip : $(EXECUTABLE)$(EXE)
	rm -f $(APACHETEST)/mod_gzip.obj
	cd $(APACHETEST); $(SAFECC) \
                       --keep=. $(APATCH) \
                        $(APACHECFLAGS) \
                        $(OBJOUT)./mod_gzip.obj \
                        mod_gzip.c

apache/rewrite: $(EXECUTABLE)$(EXE)
	rm -f $(APACHETEST)/mod_gzip.obj
	cd $(APACHETEST); $(SAFECC) \
                       --keep=. $(APATCH) \
                        $(APACHECFLAGS) \
                        $(OBJOUT)./mod_rewrite.obj \
                        $(APACHEBASE)/modules/standard/mod_rewrite.c

