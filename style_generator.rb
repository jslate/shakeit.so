widths = { sm: 0, md: 376, lg: 769 }

sides = {
  tp: [:top],
  bt: [:bottom],
  rt: [:right],
  lt: [:left],
  hz: [:left, :right],
  vt: [:bottom, :top],
}

attrs = { pd: :padding, mg: :margin }

sizes = 1.upto(6).to_a

widths.each do |width, width_value|
  puts "@media screen and (min-width: #{width_value}px) {"

  attrs.each do |attr, attr_value|
    sides.each do |side, props|
      sizes.each do |size|
        puts "  .#{attr}-#{side}-#{width}-#{size} {"
          props.each do |prop|
            puts "    #{attr_value}-#{prop}: #{size}rem;"
          end
        puts "  }"
      end
    end
  end
  puts "}"
end
