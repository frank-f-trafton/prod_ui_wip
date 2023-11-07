#!/bin/sh

echo "Line count of .lua, .glsl, .py and .sh files (see shell script for excluded directories)"

find . \
	-not \( -path "./.git" -prune \) \
	-not \( -path "./themes/build" -prune \) \
	-type f \( -name "*.lua" -or -name "*.py" -or -name "*.sh" -or -name "*.glsl" \) \
	| xargs wc -l | sort -n
