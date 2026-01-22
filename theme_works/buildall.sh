# Stop on error
set -e

./build.sh --theme vacuum_dark --dpi 96
./build.sh --theme vacuum_dark --dpi 192
./build.sh --theme vacuum_dark --dpi 288
./build.sh --theme vacuum_light --dpi 96
./build.sh --theme vacuum_light --dpi 192
./build.sh --theme vacuum_light --dpi 288
