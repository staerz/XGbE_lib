##########################################################################################
# Generate doxygen documentation target
##########################################################################################

# doxygen config
DOXYGEN_PATH          = doxytemp
DOXYGEN_CONFIG_DIR    = config
DOXYGEN_CONFIG_FILE   = ${DOXYGEN_CONFIG_DIR}/Doxyfile
DOXYGEN_WARNINGS_FILE = doxygen
OUTPUTPDF             = Manual
FIGSDIR               = ../figs
# the including Makefile must declare the COMPONENT_NAME
# Note that no indentation is allowed here!
ifndef COMPONENT_NAME
$(error COMPONENT_NAME is undefined)
endif
# exports COMPONENT_NAME as used in the local doxyfile
export COMPONENT_ROOT_PATH = $(shell pwd | sed -E 's/(.*${COMPONENT_NAME})(.*)/\1/')
# export the current (latest) quartus version (found in the component's altera directory)
# allows to include the following line in the component's Doxyfile_local:
# INPUT += $(COMPONENT_ROOT_PATH)/altera/$(QUARTUS_VERSION)/
export QUARTUS_VERSION = $(shell ls ${COMPONENT_ROOT_PATH}/altera 2> /dev/null | sort -V | grep -v Manifest | tail -n1)

# we directly use the $(INPUT) as defined in the Doxyfile_local
include Doxyfile_local
export PROJECT_NUMBER = $(shell git describe --tags --exact-match 2> /dev/null || ([ -n "$(CI)" ] && echo $(CI_COMMIT_REF_NAME) || git branch --show-current))

#-------------------------------------------------------------------------------
# Set path for pdflatex on lxplus
LXPLUSPATH = /afs/cern.ch/sw/XML/texlive/latest/bin/x86_64-linux
ifneq "$(wildcard $(LXPLUSPATH) )" ""
	PATH  := $(LXPLUSPATH):$(PATH)
endif
SHELL := env PATH=$(PATH) /bin/bash
#-------------------------------------------------------------------------------

# source and target files
JSONFIGS := $(shell find $(FIGSDIR) -name '*.json' 2>/dev/null)
PDFFIGS := $(JSONFIGS:%.json=%.pdf)

# use the json2pdf to create the target files
$(FIGSDIR)/%.pdf: $(FIGSDIR)/%.json
	${DOXYGEN_CONFIG_DIR}/wavedrom/json2pdf $(FIGSDIR)

# this is the default main target:
${OUTPUTPDF}_${COMPONENT_NAME}.pdf: ${DOXYGEN_PATH}/latex
	${DOXYGEN_CONFIG_DIR}/beautifyDoxygen.sh
	make -C $< all > ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-latex.log
	cp $</refman.pdf $@

# and additional goal (not run by default) for the CI to be called explicitly
doxygen-junit.xml: ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-stderr.log
	doxygen_junit --input $< --output $@
	config/doxygenJunitHelper.sh ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-stdout.log $< $@

# actual document creation, depending on the figures and the input from doxygen
# unfortunately, it's not easy to also take into account the $(EXCLUDE)
# that would require some additional parsing of $(INPUT) and is just not worth the effort
${DOXYGEN_PATH}/latex ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-stderr.log: $(PDFFIGS) $(INPUT)
	doxygen ${DOXYGEN_CONFIG_FILE} 2> ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-stderr.log > ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-stdout.log

# create the html content by temporarily enabling html output
html: $(PDFFIGS)
	@sed -i 's/\(GENERATE_HTML\s*= \)NO/\1YES/g' ${DOXYGEN_CONFIG_FILE}
	@sed -i 's/\(GENERATE_LATEX\s*= \)YES/\1NO/g' ${DOXYGEN_CONFIG_FILE}
	doxygen ${DOXYGEN_CONFIG_FILE} 2> ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-html-stderr.log > ${DOXYGEN_WARNINGS_FILE}_${COMPONENT_NAME}-html-stdout.log
	@sed -i 's/\(GENERATE_HTML\s*= \)YES/\1NO/g' ${DOXYGEN_CONFIG_FILE}
	@sed -i 's/\(GENERATE_LATEX\s*= \)NO/\1YES/g' ${DOXYGEN_CONFIG_FILE}
	mv ${DOXYGEN_PATH}/html .

clean:
	rm -rf ${DOXYGEN_PATH}
	rm -f ${DOXYGEN_WARNINGS_FILE}*

cleanwave:
	${DOXYGEN_CONFIG_DIR}/wavedrom/cleanupWavedrom $(FIGSDIR)

cleanall: clean cleanwave
	rm -f ${OUTPUTPDF}*
	rm -rf html
