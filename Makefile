.PHONY: all clean build-lab run-lab
.SECONDEXPANSION:
.SECONDARY:

ifneq 'yes' '$(VERBOSE)'
hidecmd := @
endif

CC := gcc
CFLAGS += -Wall -Wextra -Werror -Wno-missing-field-initializers -Werror=vla -g
LDFLAGS +=

system := $(shell uname)

ifneq 'MINGW' '$(patsubst MINGW%,MINGW,$(system))'
CFLAGS += -std=c11
else
CFLAGS += -std=gnu11
endif

labs := $(filter-out out Makefile README.md,$(wildcard *))

lab_sources = $(wildcard $(1)/*.c)
lab_headers = $(wildcard $(1)/*.h)
lab_objects = $(patsubst %.c,out/%.o,$(call lab_sources,$(1)))
lab_header_checks = $(addprefix out/,$(addsuffix .header,$(call lab_headers,$(1))))

objects := $(sort $(foreach lab,$(labs),$(call lab_objects,$(lab))))
header_checks := $(sort $(foreach lab,$(labs),$(call lab_header_checks,$(lab))))

all: $(addprefix build-,$(labs))

clean:
	rm -rf out

build-lab: $$(call lab_objects,.) $$(call lab_header_checks,.) | out/.dir
	$(if $(filter $(call lab_objects,.),$(?)),,@echo [BUILD] Nothing to be done.)
	$(if $(filter $(call lab_objects,.),$(?)),$(if $(SILENT),,@echo [LINK] $(notdir $(CURDIR))) $(hidecmd)$(CC) $(CFLAGS) $(LDFLAGS) -o out/lab $(filter-out %.header,$^),)

run-lab: build-lab
	$(hidecmd)out/lab $(ARGS)

$(addprefix run-,$(labs)): run-%: build-%
	$(hidecmd)out/$*/lab $(ARGS)

$(addprefix build-,$(labs)): build-%: out/%/lab

out/%/lab: $$(call lab_objects,%) $$(call lab_header_checks,%) | $$(@D)/.dir
	$(if $(SILENT),,@echo [LINK] $(patsubst out/%/lab,%,$@))
	$(hidecmd)$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(filter-out %.header,$^)

$(objects): out/%.o: %.c | $$(@D)/.dir
	$(if $(SILENT),,@echo "[ C  ]" $<)
	$(hidecmd)$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

$(header_checks): out/%.header: % | $$(@D)/.dir
	$(if $(SILENT),,@echo [HDR ] $<)
	$(hidecmd)$(CC) $(CFLAGS) -Wno-unused-const-variable -c -fsyntax-only $<
	@touch $@

%/.dir:
	@mkdir -p $(@D) && touch $@

include $(wildcard $(patsubst %.o,%.d,$(objects)))

