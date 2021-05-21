#!/bin/bash
#
# A script for clang-format-diff validation. Pulls a diff of the current branch
# from git. Suggests clang-format replacements for any violations within the
# diff. A patch is generated for the user to apply.
#
# Path Output: clang_format.patch

# Don't run this script with pending changes! It may modify your files.
if [ -n "$(git status --porcelain)" ]; then
	echo "ERROR: Changes reported by git, revert and retry"
	exit 1
fi

if [ ! -x ${CLANG_FORMAT_DIFF} ]; then
	echo "ERROR: Please set CLANG_FORMAT_DIFF and retry"

	# You may find the file at one of the following locations:
	#  - /usr/lib/llvm/11/share/clang/clang-format-diff.py
	#  - /usr/share/clang/clang-format-12/clang-format-diff.py
	exit 1
fi

if [ -z ${DIFF_FILTER_LIST} ]; then
	DIFF_FILTER_LIST="*.cpp *.c *.h"
fi

# Copy `.clang-format`, skipping if one already exists
cp -n contrib/clang-format.txt .clang-format

# Apply all clang-format-diff changes to the working directory
BRANCH_POINT_SHA=$(git merge-base HEAD remotes/origin/master)
git diff -U0 --no-color ${BRANCH_POINT_SHA} -- ${DIFF_FILTER_LIST} | ${CLANG_FORMAT_DIFF} -i -p1

# Create patch file of all clang-format suggested changes
git diff > clang_format.patch

# A non-empty `clang_format.patch` indicates clang-format violations
if [ -s clang_format.patch ]; then
	echo "FAIL: Your changes are not clang-format compliant!"
	echo ""
	echo "Please inspect and apply clang_format.patch:"
	echo "  git apply clang_format.patch"
	echo ""
	echo "--------------------------------------------------"
	echo ""
	cat clang_format.patch
	exit 1
fi

echo "PASS: Your changes are clang-format compliant!"
rm clang_format.patch
exit 0
