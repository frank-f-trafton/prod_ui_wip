
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

love12d svg2png.lua --source vacuum_dark --dpi $dpi
echo Running atlas_build...
love12d atlas_build.lua --img-source output/$dpi/vacuum_dark --dest output/$dpi --bleed 1

echo Copying output to themes directory...
rm -rf ../prod_ui/resources/textures/$dpi
mkdir -p ../prod_ui/resources/textures/$dpi
cp output/$dpi/atlas.lua ../prod_ui/resources/textures/$dpi/atlas.lua
cp output/$dpi/atlas.png ../prod_ui/resources/textures/$dpi/atlas.png
