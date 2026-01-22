# Stop on error
set -e

./build.sh --theme vacuum_dark --tex-scale 1
./build.sh --theme vacuum_dark --tex-scale 2
./build.sh --theme vacuum_dark --tex-scale 3
./build.sh --theme vacuum_light --tex-scale 1
./build.sh --theme vacuum_light --tex-scale 2
./build.sh --theme vacuum_light --tex-scale 3
