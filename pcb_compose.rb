# compose PCB images to a foldable paper

require 'rubygems'
require 'RMagick'

DPI=1200

# how far apart are the boards in inches
SEPARATION=1.0
SEPARATION_PX=(SEPARATION*DPI).to_i


top= Magick::ImageList.new("etchtest.GTL.eps") { self.density=DPI }
bottom= Magick::ImageList.new("etchtest.GBL.eps") { self.density=DPI }

out=Magick::Image.new(top.columns,top.rows*2+SEPARATION_PX)

out.composite!(top,0,0,Magick::OverCompositeOp)
out.composite!(bottom.flip,0,top.rows+SEPARATION_PX,Magick::OverCompositeOp)

out.write("out.png")
