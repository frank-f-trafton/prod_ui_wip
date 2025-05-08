#!/bin/bash

if [ ! -d "output" ]; then
	echo "making directory: output"
	mkdir output
fi

if [ ! -d "output/$2" ]; then
	echo "making directory: output/$2"
	mkdir output/$2
fi

if [ ! -d "output/$2/$1" ]; then
	echo "making directory: output/$2/$1"
	mkdir output/$2/$1
fi

for filename in $1/*.svg; do
	echo "exporting: $filename"
	out_fname="${filename%.*}.png"
	inkscape --export-filename=output/$2/$out_fname --export-dpi=$2 $filename
done
