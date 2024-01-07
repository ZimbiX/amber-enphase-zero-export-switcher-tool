# Usage:
#
#   There are three different output modes:
#     time gnuplot -p -c envoy.gnuplot envoy.csv qt; pkill gnuplot
#     time gnuplot -p -c envoy.gnuplot envoy.csv png > envoy-plot.png
#     time gnuplot -p -c envoy.gnuplot envoy.csv svg > envoy-plot.svg
#
#   Another argument can be provided after the format to customise how many hours ago the graph covers back to
#
#   Output to terminal (Kitty):
#     time (gnuplot -p -c envoy.gnuplot envoy.csv svg | convert svg:- bmp:- | icat)
#     time (gnuplot -p -c envoy.gnuplot envoy.csv png | icat) # twice as fast, but lines are not anti-aliased

InputFile = ARG1
Format = ARG2
Hours = ARG3
if (Hours eq "") Hours = "24"

termSize = "size 2480,1100"
if (Format eq "qt") termSize = ""

set terminal Format linewidth 2 @termSize font 'Arial,14'

set datafile separator ','

set xlabel "Time"
set xdata time
set timefmt "%Y-%m-%dT%H:%M:%S"
set format x "%Y-%m-%d\n%H:%M:%S"
set xtics out

set ylabel "Power (W)"
set ytics out
set ytics 1000 nomirror
set mytics 5

# set y2label "Voltage"
# set y2range [225:255]
# set y2tics out
# set y2tics auto
# set my2tics 1

set style line 100 linetype 1 linecolor rgb "#000000" linewidth 1
set style line 101 linetype 1 linecolor rgb "#888888" linewidth 1
set style line 102 linetype 1 linecolor rgb "#BBBBBB" linewidth 0.7

set xzeroaxis linestyle 100

set grid ytics mytics ls 101, ls 102

set key top outside

set style fill solid 1.0

Seconds = floor(Hours * 60 * 60)
Now = time(0)
StartAtEpochS = Now - Seconds
StartAtStr = system("date +%Y-%m-%dT%H:%M:%S -d @".StartAtEpochS)

set xrange [StartAtStr:]
# set xrange ["2022-12-31T09:00:00":"2022-12-31T13:00:00"]

Channels = 4
LinesCount = Channels * Seconds

plot "<tail -".LinesCount." ".InputFile." | awk '$1~/eim/'              " using 2:3 title 'Production' with lines \
   , "<tail -".LinesCount." ".InputFile." | awk '$1~/total-consumption/'" using 2:3 title 'Consumption (total)' with lines \
   , "<tail -".LinesCount." ".InputFile." | awk '$1~/net-consumption/'  " using 2:3 title 'Consumption (net)' with lines \
   # , "<tail -".LinesCount." ".InputFile." | awk '$1~/voltage/'          " using 2:3 title 'Voltage' axis x1y2 with lines \

while (Format eq "qt") { pause 3; replot }
