# required parameters:
# $1: name of the stdout logfile from doxygen
# $2: name of the stderr logfile from doxygen
# $3: name of the doxygen junit file that shall be extended

# check if the parameters were properly passed
if [ "$#" -ne 3 ]; then
  echo "Requiring 3 parameters: doxygen_stdout_logfile doxygen_stderr_logfile doxygen_junit_file"
  exit 1
fi
ls "$1" 1> /dev/null || exit 2
ls "$2" 1> /dev/null || exit 3
ls "$3" 1> /dev/null || exit 4

# we need a file to store temporary results
TMPFILE=.doxygened_files.tmp

# some beautification: Remove the base path
LOCALPATH=$(pwd | sed 's|doc/Doxygen||g;s|components/fpga/||g')

# parse doxygen output and retrieve files that were parsed by doxygen
cat "$1" | grep "^Preprocessing .*\.\.\.$" | sed "s/^Preprocessing //g;s/...$//g" > ${TMPFILE}

# remove files from list that had errors
for i in $(cat ${TMPFILE}); do grep -q $i "$2" && sed -i "\|$i|d" ${TMPFILE}; done

# remove LOCALPATH from file names
sed -i "s|${LOCALPATH}||g" "$3"

# remove the trailing '</testsuite>' from the original report
sed -i "s|</testsuite>|\n|g" "$3"

# add all passed files as a test cases
for i in $(cat ${TMPFILE}); do
  echo "  <testcase name=\"${i/${LOCALPATH}/}\" file=\"${i/${LOCALPATH}/}\"></testcase>" >> "$3"
done

# and now add the end of testsuite again
echo "</testsuite>" >> "$3"

# clean up
rm ${TMPFILE}