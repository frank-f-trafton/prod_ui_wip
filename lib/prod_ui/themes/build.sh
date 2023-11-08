
# NOTE: This is a quick-and-dirty script that only outputs at 96 DPI (DPI scale of 1.0).
# It also requires that LÖVE 12 is aliased to 'love12d'.
echo Running svg2png...
cd build
love12d svg2png.lua --source vacuum_dark --dpi 96
echo Running atlas_build...
love12d atlas_build.lua --img-source output/96/vacuum_dark --dest output/96 --bleed 1
echo Copying output to themes directory...
cd ..
rm -rf vacuum/text/96/*
cp build/output/96/atlas.lua vacuum/tex/96/atlas.lua
cp build/output/96/atlas.png vacuum/tex/96/atlas.png
