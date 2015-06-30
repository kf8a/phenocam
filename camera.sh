PATH=/usr/bin:$PATH

NOW=$(date +"%F_%H_%M_%S")
PLOT=g4

if [ `/usr/bin/ruby night.rb` ];
then
raspistill -rot 270 -awb off -awbg 1.4,1.5 -o images/$PLOT-$NOW.jpg
scp images/$PLOT-$NOW.jpg phenology@oshtemo.kbs.msu.edu:/var/www/phenology/input/
fi
