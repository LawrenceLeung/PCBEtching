# compose Top/Bottom of PCB images to a single paper for faster processing

require 'rubygems'
require 'RMagick'

DPI=1200

# how far apart are the boards in inches
SEPARATION=1.0
SEPARATION_PX=(SEPARATION*DPI).to_i

FILENAME="etchtest"

LAYER_PAIRS={ :signal => {:top=>"GTL", :bottom=>"GBL"},
    :mask => {:top=>"GTS", :bottom=>"GBS"} 
 }

LAYER_PAIRS.each_pair { |layer, layer_data | 
    puts "Processing #{layer}"
    top= Magick::ImageList.new("#{FILENAME}.#{layer_data[:top]}.eps") { self.density=DPI }
    bottom= Magick::ImageList.new("#{FILENAME}.#{layer_data[:bottom]}.eps") { self.density=DPI }

    out=Magick::Image.new(top.columns,top.rows*2+SEPARATION_PX)

    out.composite!(top,0,0,Magick::OverCompositeOp)
    out.composite!(bottom.flip,0,top.rows+SEPARATION_PX,Magick::OverCompositeOp)

    out.write("#{layer}.png")
}
