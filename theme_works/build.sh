
# NOTE: This is a quick-and-dirty script.
# It requires the following aliases:
# LÖVE 12 -> 'love12d'
# Inkscape 1.3.2 -> 'inkscape132'


# Stop script at the first failed command.
set -e

# Config
dpi=96
theme=vacuum_dark

while [[ $# -gt 0 ]]; do
	case $1 in
		--dpi)
			dpi="$2";
			shift
			shift
		;;

		--theme)
			theme="$2";
			shift
			shift
		;;

		*)
		echo Unknown setting.
		exit 1
		;;
	esac
done

echo DPI: $dpi
echo Running svg2png...

love12d svg2png.lua --source $theme --dpi $dpi
echo Running atlas_build...
love12d atlas_build.lua --png-dir output/$theme/$dpi/png --dest output/$theme/$dpi --bleed 1

echo Copying output to themes directory...
mkdir -p ../prod_ui/resources/textures/$dpi
rm -rf ../prod_ui/resources/textures/$dpi/$theme.*
cp output/$theme/$dpi/atlas.lua ../prod_ui/resources/textures/$dpi/$theme.lua
cp output/$theme/$dpi/atlas.png ../prod_ui/resources/textures/$dpi/$theme.png

echo Done.
