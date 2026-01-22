
# NOTE: This is a quick-and-dirty script.
# It requires following programs:
# * LÖVE 12, aliased to 'love12d'
# * rsvg-convert


# Stop script at the first failed command.
set -e

# Config
tex_scale=96
theme=vacuum_dark

while [[ $# -gt 0 ]]; do
	case $1 in
		--tex-scale)
			tex_scale="$2";
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

echo Scale: $tex_scale
echo Running svg2png...

love12d svg2png.lua --source $theme --tex-scale $tex_scale
echo Running atlas_build...
love12d atlas_build.lua --png-dir output/$theme/$tex_scale/png --dest output/$theme/$tex_scale --bleed 1

echo Copying output to themes directory...
mkdir -p ../prod_ui/resources/textures/$tex_scale
rm -rf ../prod_ui/resources/textures/$tex_scale/$theme.*
cp output/$theme/$tex_scale/atlas.lua ../prod_ui/resources/textures/$tex_scale/$theme.lua
cp output/$theme/$tex_scale/atlas.png ../prod_ui/resources/textures/$tex_scale/$theme.png

echo Done.
