#!/bin/bash
# EMACS settings: -*-  tab-width: 2; indent-tabs-mode: nil -*-
# vim: tabstop=2:shiftwidth=2:expandtab
# kate: tab-width 2; replace-tabs on; indent-width 2;
################################################################################
#
# Run over the tex files produced by Doxygen and do some reformatting
#
################################################################################
# Author: Steffen Staerz <steffen.staerz@cern.ch>
################################################################################

TEXDIR=doxytemp/latex/

# fix the makefile to halt on error (for local compilation)
sed -i "s/pdflatex/pdflatex -interaction=batchmode/g" ${TEXDIR}/Makefile

# few modifications in main tex document are required:
find ${TEXTDIR} -name "refman.tex" \
    -exec sed -i '/fixltx2e/d' {} \; \
    -exec sed -i '/discretionary/d' {} \;

# now some style modifications on tex sub documents
# for loop for easily extending other extensions
for ext in tex; do
  # find all files matching, then invoke sed to:
  # - replace empty spaces enclosed by 'vhdlchar' by simply spaces (to really separate words)
  # - add extra space before \bfseries: for type definitions
  find ${TEXDIR} -name "*.${ext}" \
    -exec sed -i 's/\\textcolor{vhdlchar}{ }/ /g' {} \; \
    -exec sed -i 's/\\+//g' {} \; \
    -exec sed -i 's/{\\bfseries/ {\\bfseries/g' {} \;
done

echo "LaTeX beautification done."