# Copyright (c) 2022 Status Research & Development GmbH. Licensed under
# either of:
# - Apache License, version 2.0
# - MIT license
# at your option. This file may not be copied, modified, or distributed except
# according to those terms.
BUILD_SYSTEM_DIR := vendor/nimbus-build-system
LINK_PCRE := 0
LOG_LEVEL := TRACE

# we don't want an error here, so we can handle things later, in the ".DEFAULT" target
-include $(BUILD_SYSTEM_DIR)/makefiles/variables.mk


ifeq ($(NIM_PARAMS),)
# "variables.mk" was not included, so we update the submodules.
GIT_SUBMODULE_UPDATE := git submodule update --init --recursive
.DEFAULT:
	+@ echo -e "Git submodules not found. Running '$(GIT_SUBMODULE_UPDATE)'.\n"; \
		$(GIT_SUBMODULE_UPDATE); \
		echo
# Now that the included *.mk files appeared, and are newer than this file, Make will restart itself:
# https://www.gnu.org/software/make/manual/make.html#Remaking-Makefiles
#
# After restarting, it will execute its original goal, so we don't have to start a child Make here
# with "$(MAKE) $(MAKECMDGOALS)". Isn't hidden control flow great?

else # "variables.mk" was included. Business as usual until the end of this file.


##########
## Main ##
##########
.PHONY: all test update clean

# default target, because it's the first one that doesn't start with '.'
all: | wakunode1 example1 sim1 

test: | testwhisper testwaku1

waku.nims:
	ln -s waku.nimble $@

update: | update-common
	rm -rf waku.nims && \
		$(MAKE) waku.nims $(HANDLE_OUTPUT)

clean:
	rm -rf build

# must be included after the default target
-include $(BUILD_SYSTEM_DIR)/makefiles/targets.mk

## Possible values: prod; debug
TARGET ?= prod

## Git version
GIT_VERSION ?= $(shell git describe --abbrev=6 --always --tags)
NIM_PARAMS := $(NIM_PARAMS) -d:git_version=\"$(GIT_VERSION)\"

## Pass CPU architecture to C compiler, use basic x86-64 instruction set by default
ARCHITECTURE ?= "x86-64"
NIM_PARAMS := $(NIM_PARAMS) --passC:\"-march=$(ARCHITECTURE)\"

endif

##################
## Dependencies ##
##################
.PHONY: deps libbacktrace

deps: | deps-common nat-libs waku.nims


### nim-libbacktrace

# "-d:release" implies "--stacktrace:off" and it cannot be added to config.nims
ifeq ($(USE_LIBBACKTRACE), 0)
NIM_PARAMS := $(NIM_PARAMS) -d:debug -d:disable_libbacktrace
else
NIM_PARAMS := $(NIM_PARAMS) -d:release
endif

libbacktrace:
	+ $(MAKE) -C vendor/nim-libbacktrace --no-print-directory BUILD_CXX_LIB=0

clean-libbacktrace:
	+ $(MAKE) -C vendor/nim-libbacktrace clean $(HANDLE_OUTPUT)

# Extend deps and clean targets
ifneq ($(USE_LIBBACKTRACE), 0)
deps: | libbacktrace
endif

clean: | clean-libbacktrace


#################
## Waku legacy ##
#################
.PHONY: testwhisper testwaku1 wakunode1 example1 sim1

testwhisper: | build deps
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim testwhisper $(NIM_PARAMS) waku.nims

testwaku1: | build deps
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim test1 $(NIM_PARAMS) waku.nims

wakunode1: | build deps
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim wakunode1 $(NIM_PARAMS) waku.nims

example1: | build deps
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim example1 $(NIM_PARAMS) waku.nims

sim1: | build deps wakunode1
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim sim1 $(NIM_PARAMS) waku.nims


###################
## Documentation ##
###################
.PHONY: docs

# TODO: Remove unused target
docs: | build deps
	echo -e $(BUILD_MSG) "build/$@" && \
		$(ENV_SCRIPT) nim doc --run --index:on --project --out:.gh-pages waku/waku.nim waku.nims
