ROOTDIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILDDIR := $(ROOTDIR)/build
SRCDIR := $(BUILDDIR)/src
LIBDIR := $(BUILDDIR)/lib
INCLUDEDIR := $(BUILDDIR)/include

USRDIR := $(ROOTDIR)/usr
JULIADIR := $(ROOTDIR)/julia

TAR := $(shell which gtar 2>/dev/null || which tar 2>/dev/null)

OPENSPECFUN_VERS := $(shell cat VERSION)
OPENLIBM_VERS := 0.5.4

ifeq ($(OS),Windows_NT)
override OS := WINNT
JULIA_EXE := C:\projects\julia-binary.exe
else
override OS := $(shell uname)
JULIA_EXE := $(JULIADIR)/bin/julia
endif

# Delay expansion here since Julia might not have been downloaded yet
JULIA_SHLIB_DIR = $(shell $(JULIA_EXE) -e "println(JULIA_HOME)")/../lib/julia

ifeq ($(ARCH),i686)
URL_ARCH := x86
BITS := 32
else
URL_ARCH := x64
BITS := 64
endif

ifeq ($(OS),WINNT)
OUT_OS := win
URL_OS := winnt
URL_SUFFIX := win$(BITS).exe
ZIP_EXT := zip
else ifeq ($(OS),Darwin)
OUT_OS := osx
URL_OS := osx
URL_SUFFIX := osx.dmg
ZIP_EXT := tar.gz
else
OUT_OS := linux
URL_OS := linux
URL_SUFFIX := linux$(BITS).tar.gz
ZIP_EXT := tar.gz
endif

JULIA_URL := https://julialangnightlies-s3.julialang.org/bin/$(URL_OS)/$(URL_ARCH)/julia-latest-$(URL_SUFFIX)

TARBALL := libopenspecfun-$(OPENSPECFUN_VERS)-$(OUT_OS)-$(ARCH).$(ZIP_EXT)

ifneq (,$(findstring CYGWIN,$(shell uname)))
FC := $(shell uname -m)-w64-mingw32-gfortran
else
FC := gfortran
endif

ifeq ($(OS),Darwin)
USEGCC := 0
USECLANG := 1
else
USEGCC := 1
USECLANG := 0
endif

ifeq ($(OS),WINNT)
SHLIB_EXT := dll
else ifeq ($(OS),Darwin)
SHLIB_EXT := dylib
else
SHLIB_EXT := so
endif

ifeq ($(OS),WINNT)
RPATH_ESCAPED_ORIGIN :=
else ifeq ($(OS),Darwin)
RPATH_ESCAPED_ORIGIN := -Wl,-rpath,'@loader_path/'
else
RPATH_ESCAPED_ORIGIN := -Wl,-rpath,'\$$\$$ORIGIN' -Wl,-z,origin
endif

ifeq ($(ARCH),i686)
CC += -m32
FC += -m32
else ifeq ($(ARCH),x86_64)
CC += -m64
FC += -m64
endif

JFFLAGS := -O2
ifneq ($(OS),WINNT)
JFFLAGS += -fPIC
LDFLAGS += -L$(LIBDIR)
endif

MAKE_FLAGS := DESTDIR="" prefix=$(BUILDDIR) bindir=$(BINDIR) libdir=$(LIBDIR) \
    shlibdir=$(LIBDIR) includedir=$(INCLUDEDIR) O=

OPENSPECFUN_CFLAGS := -O3 -std=c99

# NOTE: We're setting USE_OPENLIBM=1 here since that's the default for the release builds
# of Julia. Doing a source build of Julia allows you to use the system's libm, but we'll
# ignore that possibility for now.
OPENSPECFUN_FLAGS := ARCH="$(ARCH)" OS="$(OS)" CC="$(CC)" FC="$(FC)" \
    USEGCC=$(USEGCC) USECLANG=$(USECLANG) USE_OPENLIBM=1 FFLAGS="$(JFFLAGS)" \
    CFLAGS="$(CFLAGS) $(OPENSPECFUN_CFLAGS)" LDFLAGS="$(LDFLAGS) $(RPATH_ESCAPED_ORIGIN)"

default: $(LIBDIR)/libopenspecfun.$(SHLIB_EXT)
package: $(ROOTDIR)/$(TARBALL)

define dir_rule
$(1):
	@mkdir -p $(1)
endef

$(foreach d,$(SRCDIR) $(LIBDIR) $(INCLUDEDIR),$(eval $(call dir_rule,$(d))))

$(JULIADIR):
ifeq ($(OS),WINNT)
	cmd //c "appveyor DownloadFile $(JULIA_URL) -FileName C:\projects\julia-binary.exe"
	touch $@
else ifeq ($(OS),Darwin)
	curl -s -L --retry 7 -o julia.dmg $(JULIA_URL)
	-mkdir $(ROOTDIR)/juliamnt
	hdiutil mount -readonly -mountpoint $(ROOTDIR)/juliamnt julia.dmg
	cp -a $(ROOTDIR)/juliamnt/*.app/Contents/Resources/julia $(ROOTDIR)
	hdiutil unmount $(ROOTDIR)/juliamnt
	-rm -rf $(ROOTDIR)/juliamnt
else
	-mkdir -p $(JULIADIR)
	curl -sL --retry 7 $(JULIA_URL) | $(TAR) -C $(JULIADIR) -x -z --strip-components=1 -f -
endif

$(LIBDIR)/libopenlibm.$(SHLIB_EXT): | $(LIBDIR) $(JULIADIR)
	cp -a $(JULIA_SHLIB_DIR)/libopenlibm.* $(dir $@)

$(SRCDIR)/openlibm-$(OPENLIBM_VERS).tar.gz: | $(SRCDIR)
	curl -fkL --connect-timeout 15 -y 15 \
	    https://github.com/JuliaLang/openlibm/archive/v$(OPENLIBM_VERS).tar.gz -o $@

$(SRCDIR)/openlibm: $(SRCDIR)/openlibm-$(OPENLIBM_VERS).tar.gz
	-mkdir -p $@
	$(TAR) -C $@ --strip-components 1 -xf $<

$(INCLUDEDIR)/openlibm/openlibm.h: $(SRCDIR)/openlibm | $(INCLUDEDIR)
	-mkdir -p $(dir $@)
	cp -f $</include/* $(dir $@)
	cp -f $</src/*.h $(dir $@)

$(SRCDIR)/openspecfun-$(OPENSPECFUN_VERS).tar.gz: | $(SRCDIR)
	curl -fkL --connect-timeout 15 -y 15 \
	    https://github.com/JuliaLang/openspecfun/archive/v$(OPENSPECFUN_VERS).tar.gz -o $@

$(SRCDIR)/Makefile: $(SRCDIR)/openspecfun-$(OPENSPECFUN_VERS).tar.gz
	$(TAR) -C $(dir $@) --strip-components 1 -xf $<

$(LIBDIR)/libopenspecfun.$(SHLIB_EXT): $(SRCDIR)/Makefile $(INCLUDEDIR)/openlibm/openlibm.h $(LIBDIR)/libopenlibm.$(SHLIB_EXT)
	$(MAKE) -C $(dir $<) install $(OPENSPECFUN_FLAGS) $(MAKE_FLAGS)
ifneq ($(OS),WINNT)
	$(ROOTDIR)/fixup-libgfortran.sh -v $(dir $@)
endif

$(USRDIR)/lib/libopenspecfun.$(SHLIB_EXT): $(LIBDIR)/libopenspecfun.$(SHLIB_EXT)
	-mkdir -p $(USRDIR)
	cp -fR $(LIBDIR) $(USRDIR)

$(ROOTDIR)/$(TARBALL): $(USRDIR)/lib/libopenspecfun.$(SHLIB_EXT)
ifeq ($(OS),WINNT)
	chdir $(dir $@)
	7z a $(TARBALL) usr
else
	(cd $(dir $@); $(TAR) -cvzf $@ usr)
endif

test:
	$(JULIA_EXE) test.jl

clean:
	-rm -rf $(BUILDDIR)
	-rm -rf $(USRDIR)
	-rm $(ROOTDIR)/$(TARBALL)

clean-julia: clean
	-rm -rf $(JULIADIR)

.PHONY: default clean package clean-julia test
