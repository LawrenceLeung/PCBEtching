#!/usr/bin/ruby
# compose Top/Bottom of PCB images to a single paper for faster processing.  Works great for small PCBs <5" or so

# args: <eagle design name>

require 'rubygems'
require 'RMagick'


#target eagle design name.  Defaults to etchtest...
FILENAME=ARGV[0] || "etchtest"

puts "Processing '#{FILENAME}'..."

# output image DPI
DPI=1200

def inch_to_px(i)
    (i*DPI).to_i
end

# how far apart are the boards in inches
SEPARATION=1.0
SEPARATION_PX=inch_to_px(SEPARATION)

# how far is the alignment mark from the design in inch.  Should be < SEPARATION/2
ALIGNMENT_DISTANCE=0.2
ALIGNMENT_DISTANCE_PX=inch_to_px(ALIGNMENT_DISTANCE)

ALIGNMENT_SIZE=inch_to_px(0.05)
ALIGNMENT_WIDTH_PX=4
ALIGNMENT_WIDTH_THIN_PX=2

ADDITIONAL_BORDER_PX=ALIGNMENT_DISTANCE_PX+ALIGNMENT_SIZE*2


LAYER_PAIRS={ :signal => {:top=>"GTL", :bottom=>"GBL",:alignment_marks=>true},
    :mask => {:top=>"GTS", :bottom=>"GBS"} 
 }


# Draws the alignment target
def draw_alignment_mark(draw,center_x,center_y)
     draw.stroke('black')

     draw.stroke_width(ALIGNMENT_WIDTH_PX);
     #Vertical,thick
     draw.line(center_x,center_y+ALIGNMENT_SIZE,
                center_x,center_y+(ALIGNMENT_SIZE/4))
     draw.line(center_x,center_y-ALIGNMENT_SIZE,
                center_x,center_y-(ALIGNMENT_SIZE/4))

     #Horiz, thick
     draw.line(center_x+ALIGNMENT_SIZE,center_y,
                center_x+ALIGNMENT_SIZE/4,center_y)
     draw.line(center_x-ALIGNMENT_SIZE/4,center_y,
                center_x-ALIGNMENT_SIZE,center_y)
     
     #Thin sections
     draw.stroke_width(ALIGNMENT_WIDTH_THIN_PX);
     #Vert
     draw.line(center_x,center_y+(ALIGNMENT_SIZE/4),
                center_x,center_y-(ALIGNMENT_SIZE/4))

     #Horiz
     draw.line(center_x-ALIGNMENT_SIZE/4,center_y,
                center_x+ALIGNMENT_SIZE/4,center_y)
     

end



LAYER_PAIRS.each_pair { |layer, layer_data | 
    puts "Layer: #{layer}.png"
    top= Magick::ImageList.new("#{FILENAME}.#{layer_data[:top]}.eps") { self.density=DPI }
    bottom= Magick::ImageList.new("#{FILENAME}.#{layer_data[:bottom]}.eps") { self.density=DPI }

    out=Magick::Image.new(top.columns+ADDITIONAL_BORDER_PX*2,top.rows*2+SEPARATION_PX+ADDITIONAL_BORDER_PX*2)    

    # compose top, bottom ontop one page
    out.composite!(top,ADDITIONAL_BORDER_PX,ADDITIONAL_BORDER_PX,Magick::OverCompositeOp)
    out.composite!(bottom.flip,ADDITIONAL_BORDER_PX,ADDITIONAL_BORDER_PX+top.rows+SEPARATION_PX,Magick::OverCompositeOp)

    if (layer_data[:alignment_marks])
        d = Magick::Draw.new

        # Place marks at approx x= left-AD, 1/5, 3/4, right+AD  (intentionally skewed to prevent 180' mistakes)
        # and y= AD, top+AD, bottom-AD, bottom+AD
        alignment_x_positions=[ADDITIONAL_BORDER_PX-ALIGNMENT_DISTANCE_PX,
                        ADDITIONAL_BORDER_PX+top.columns/5,
                        ADDITIONAL_BORDER_PX+((top.columns*3)/4),
                        top.columns+ALIGNMENT_DISTANCE_PX]
        alignment_y_positions=[ADDITIONAL_BORDER_PX-ALIGNMENT_DISTANCE_PX, ADDITIONAL_BORDER_PX+top.rows+ALIGNMENT_DISTANCE_PX,
                              ADDITIONAL_BORDER_PX+top.rows+SEPARATION_PX-ALIGNMENT_DISTANCE_PX, ADDITIONAL_BORDER_PX+top.rows*2+SEPARATION_PX+ALIGNMENT_DISTANCE_PX]

        alignment_x_positions.each {|x_pos|
            alignment_y_positions.each {|y_pos| 
                draw_alignment_mark(d,x_pos,y_pos) }
            
        }
        d.draw(out);
    end

    out.write("#{layer}.png")
}

puts "Done"
