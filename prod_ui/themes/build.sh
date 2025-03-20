
# NOTE: This is a quick-and-dirty script.
# It requires the following aliases:
# LÖVE 12 -> 'love12d'
# Inkscape 1.3.2 -> 'inkscape132'


# Stop script at the first failed command.
set -e

# Config
dpi=96

while [[ $# -gt 0 ]]; do
	case $1 in
		--dpi)
			dpi="$2";
			shift
			shift
		;;
	esac
done

echo DPI: $dpi
echo Running svg2png...
cd build
love12d svg2png.lua --source vacuum_dark --dpi $dpi
echo Running atlas_build...
love12d atlas_build.lua --img-source output/$dpi/vacuum_dark --dest output/$dpi --bleed 1
echo Copying output to themes directory...
cd ..
rm -rf vacuum/tex/$dpi
mkdir -p vacuum/tex/$dpi
cp build/output/$dpi/atlas.lua vacuum/tex/$dpi/atlas.lua
cp build/output/$dpi/atlas.png vacuum/tex/$dpi/atlas.png
