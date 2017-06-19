require 'cairo'

COLOR_FONT_R = 0.1
COLOR_FONT_G = 0.1
COLOR_FONT_B = 0.1

COLOR_FILL_R = 0.459
COLOR_FILL_G = 1
COLOR_FILL_B = 1

COLOR_BG_R = 1
COLOR_BG_G = 0.855
COLOR_BG_B = 0.475
	

function init_cairo()
  if conky_window == nil then
    return false
  end

  cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height)

  cr = cairo_create(cs)

  font = "C64 Pro Mono"

  cairo_select_font_face(cr, font, CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
  cairo_set_source_rgba(cr, COLOR_FONT_R, COLOR_FONT_G, COLOR_FONT_B, 1)

  return true
end

function conky_main()
  if (not init_cairo()) then
    return
  end

  -- TIME
  cairo_set_font_size(cr, 64)
  cairo_set_source_rgba(cr, COLOR_FONT_R, COLOR_FONT_G, COLOR_FONT_B, 1)
  cairo_move_to(cr, 48, 110)
  cairo_show_text(cr, conky_parse("${time %H:%M}"))
  cairo_stroke(cr)
  
  
  -- DATE
  cairo_set_font_size(cr, 31)
  cairo_set_source_rgba(cr, COLOR_FONT_R, COLOR_FONT_G, COLOR_FONT_B, 1)
  cairo_move_to(cr, 52, 150)
  local time_str = string.format('%-12s',conky_parse("${time %d/%m/%Y}"))
  cairo_show_text(cr, time_str)
  cairo_stroke(cr)

  local day_str = string.format('%-12s', conky_parse("${time %a}"))
  cairo_set_font_size(cr, 22)
  cairo_move_to(cr, 115, 225)
  cairo_show_text(cr, day_str)
  cairo_stroke(cr)
  

  -- CPU GRAPH
  -- Non-linear (sqrt instead) so graph area approximatly matches usage
  
  local cx,cy = 459,94
  local height = 65
  local width = 30
  local gap = 161

  local cpu1 = 0.05 + math.sqrt(tonumber(conky_parse("${cpu cpu1}")) / 100.0) * 0.95
  local cpu2 = 0.05 + math.sqrt(tonumber(conky_parse("${cpu cpu2}")) / 100.0) * 0.95
  local cpu3 = 0.05 + math.sqrt(tonumber(conky_parse("${cpu cpu3}")) / 100.0) * 0.95
  local cpu4 = 0.05 + math.sqrt(tonumber(conky_parse("${cpu cpu4}")) / 100.0) * 0.95


  -- CPU 1
  cairo_set_source_rgba(cr, COLOR_FILL_R, COLOR_FILL_G, COLOR_FILL_B, 1)
  cairo_move_to(cr, cx, cy)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -height*cpu1)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)


  -- CPU 2
  cairo_set_source_rgba(cr, COLOR_FILL_R, COLOR_FILL_G, COLOR_FILL_B, 1)
  cairo_move_to(cr, cx + width + gap, cy)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -height*cpu2)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)


  -- CPU 3
  cairo_set_source_rgba(cr, COLOR_FILL_R, COLOR_FILL_G, COLOR_FILL_B, 1)
  cairo_move_to(cr, cx + 2*width + 2*gap, cy)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -height*cpu3)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)


  -- CPU 4
  cairo_set_source_rgba(cr, COLOR_FILL_R, COLOR_FILL_G, COLOR_FILL_B, 1)
  cairo_move_to(cr, cx + 3*width + 3*gap -1, cy)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -height*cpu4)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)

  
  -- MEMORY
  
  local memperc = tonumber(conky_parse("$memperc"))

  local row,col = 0,0
  local rows = 6
  local perc = 0.0
  local perc_incr = 100.0 / 24
  local cx,cy = 70,292
  local grid_width = 76

  for i = 1,24 do
    if (memperc < perc) then
      cairo_set_source_rgba(cr, COLOR_BG_R, COLOR_BG_G, COLOR_BG_B, 1)
      cairo_rectangle(cr, cx-grid_width/2, cy-grid_width/2, grid_width, grid_width)
    end
    cairo_fill(cr)

    row = row + 1
    cy = cy + grid_width

    if (row >= rows) then
      row = row - rows
      cy = cy - rows*grid_width
      col = col + 1
      cx = cx + grid_width
    end

    perc = perc + perc_incr
  end


  -- BATTERY PERCENTAGE

  this_batt = tonumber(conky_parse("${battery_percent BAT0}"))

  local cx,cy = 1249,710
  local width,height = 76,76
  local batt = 0.0
  local batt_incr = 100.0 / 9

  for i = 1,9 do
    if (this_batt < batt) then
       cairo_set_source_rgba(cr, COLOR_BG_R, COLOR_BG_G, COLOR_BG_B, 1)
       cairo_move_to(cr, cx, cy)
       cairo_rel_line_to(cr, width, 0)
       cairo_rel_line_to(cr, 0, -height)
       cairo_rel_line_to(cr, -width, 0)
    end
    cairo_fill(cr)

    batt = batt + batt_incr
    cy = cy - height
  end
end




-- FILE SYSTEM

function conky_fs_main()
  if (not init_cairo()) then
    return
  end

  local offset = 348
  local gap = 228
  local dn = dbox_used("${exec du -hs /home/chris/Dropbox/ | head -n1 | awk '{print $1}'}")

  draw_volume("   /", tonumber(conky_parse("${fs_used_perc /}")) , offset)
  draw_volume("Backups", tonumber(conky_parse("${fs_used_perc /media/chris/Backups/}")) , offset + gap + 1)
  
  draw_volume("Dropbox", dn , offset + 2*gap - 1)
  

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
  cr = nil
end



function dbox_used(arg)
  local str = conky_parse(arg)
  local n = tonumber(str:sub(1,-2)) / 2.5
  return n*100
end


function draw_volume(name, used, cx)
  local cy = 700
  local width,height = 57,15
  local volume_height = 65
  local filled_height = volume_height * used / 100
  local line_width = 5

  cairo_set_source_rgba(cr, COLOR_FILL_R, COLOR_FILL_G, COLOR_FILL_B, 1)
  cairo_move_to(cr, cx, cy)
  cairo_rel_line_to(cr, width, 0)
  cairo_rel_line_to(cr, 0, -filled_height)
  cairo_rel_line_to(cr, -width, 0)
  cairo_fill(cr)

  -- Drive name
  cairo_set_source_rgba(cr, COLOR_FONT_R, COLOR_FONT_G, COLOR_FONT_B, 1)
  cairo_move_to(cr, cx-5, cy - volume_height + 84)
  cairo_show_text(cr, name)
  cairo_stroke(cr)
end
