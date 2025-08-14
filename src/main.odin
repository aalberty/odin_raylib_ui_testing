package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

WIDTH :: 1024
HEIGHT :: 768
TITLE :: "Hellope!"
WORKBENCH_BG :: rl.Color{0, 85, 168, 255}

MIDX :: WIDTH / 2
MIDY :: HEIGHT / 2
FONT_SIZE :: 18

FPS :: 60

Vector2 :: struct {
    x: i32,
    y: i32,
}

Page :: struct {
    id: string,
    message: cstring,
    font_color: rl.Color,
    bg_color: rl.Color,
    components: [dynamic]string,
}

Button :: struct {
    id: string,
    text: cstring,
    font_size: i32,
    font_color: rl.Color,
    position: Vector2,
    size: Vector2,
    bg_color: rl.Color,
}

Sticky :: struct {
    id: string,
    text: cstring,
    font_size: i32,
    font_color: rl.Color,
    position: Vector2,
    size: Vector2,
    bg_color: rl.Color,
}

BUTTON_PADDING :: 50;

draw_button :: proc(btn: Button) {
    rl.DrawRectangle(btn.position.x, btn.position.y, btn.size.x, btn.size.y, btn.bg_color)
    button_center := Vector2{}
    button_center.x = btn.position.x + (btn.size.x / 2)
    button_center.y = btn.position.y + (btn.size.y / 2)
    button_text_pos := Vector2{}
    button_text_pos.x = button_center.x - (rl.MeasureText(btn.text, btn.font_size) / 2)
    button_text_pos.y = button_center.y - (btn.font_size / 2)
    rl.DrawText(btn.text, button_text_pos.x, button_text_pos.y, btn.font_size, btn.font_color)
}

draw_sticky :: proc(sticky: Sticky) {
    rl.DrawRectangle(sticky.position.x, sticky.position.y, sticky.size.x, sticky.size.y, sticky.bg_color)
    obj_center := Vector2{}
    obj_center.x = sticky.position.x + (sticky.size.x / 2)
    obj_center.y = sticky.position.y + (sticky.size.y / 2)
    obj_text_pos := Vector2{}
    obj_text_pos.x = obj_center.x - (rl.MeasureText(sticky.text, sticky.font_size) / 2)
    obj_text_pos.y = obj_center.y - (sticky.font_size / 2)
    rl.DrawText(sticky.text, obj_text_pos.x, obj_text_pos.y, sticky.font_size, sticky.font_color)
}

// returns (x_bool, y_bool); if a bool is true, it means the obj is within window bounds
// on that axis of movement
check_against_window_bounds :: proc (obj_pos: Vector2, obj_size: Vector2) -> (x: bool, y: bool) {
    left: bool = obj_pos.x >= 0
    right: bool = (obj_pos.x + obj_size.x) <= WIDTH
    top: bool = obj_pos.y >= 0
    bottom: bool = (obj_pos.y + obj_size.y) <= HEIGHT

    x = left && right
    y = top && bottom
    return x, y
}

main :: proc() {

    home_page := Page{
        id = "home_page",
        message = strings.clone_to_cstring("Hellope, and welcome to the home_page! Press 'Enter' to change to next_page."),
        font_color = rl.WHITE,
        bg_color = WORKBENCH_BG

    }

    click_me := Button{
        id = "click_me",
        text = strings.clone_to_cstring("Click me!"),
        font_size = 12,
        font_color = rl.BLACK,
        size = Vector2{250, 50},
        position = Vector2{50, HEIGHT - 50 /* <-- this click_me.size.y */ - BUTTON_PADDING},
        bg_color = rl.LIGHTGRAY,
    }

    next_page := Page{
        id = "next_page",
        message = strings.clone_to_cstring("This is next_page. Press 'Enter' to change back to home_page."),
        font_color = rl.MAGENTA,
        bg_color = rl.RAYWHITE,
    }

    stickies: [dynamic]Sticky
    currently_held: ^Sticky
    move_held_to: Vector2
    move_offset: Vector2
    last_click_timestamp: f64
    time_since_last_click: f64

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, TITLE)
    defer rl.CloseWindow() 
    rl.SetTargetFPS(FPS)

    current_page: Page = home_page
    frame_counter: i32 = 0
    frame_tally: i32 = 60
    double_click_timestamp: f64 = rl.GetTime()
    
    // TODO: verbose logging flag that can be used when exe is called
    log_frames: bool =  false
    for !rl.WindowShouldClose() {

        if log_frames {
            if frame_counter < 60 {
                frame_counter = frame_counter + 1
            }
            
            if frame_counter == 60 {
                now := rl.GetTime()
                fmt.println(frame_tally, "frames took", now, "second(s)")
                frame_counter = 0
                frame_tally = frame_tally + 60
            }
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(current_page.bg_color)
        tw := rl.MeasureText(current_page.message, FONT_SIZE)
        x := i32(MIDX - tw/2)
        y := i32(MIDY - FONT_SIZE/2)

        rl.DrawText(current_page.message, x, y, FONT_SIZE, current_page.font_color)

        // update sticky location if there's one currently held
        if currently_held != nil {
            allow_move_x, allow_move_y := check_against_window_bounds(move_held_to, currently_held.size)

            if allow_move_x {
                currently_held.position.x = move_held_to.x
            } else {
                fmt.println("WARN: Detected collision on x axis")
                if move_held_to.x < MIDX {
                    move_held_to.x = 0
                } else {
                    move_held_to.x = (WIDTH - currently_held.size.x)
                }
                currently_held.position.x = move_held_to.x
            }

            if allow_move_y {
                currently_held.position.y = move_held_to.y
            } else {
                fmt.println("WARN: Detected collision on y axis")
                if move_held_to.y < MIDY {
                    move_held_to.y = 0
                } else {
                    move_held_to.y = (HEIGHT - currently_held.size.y)
                }
                currently_held.position.y = move_held_to.y
            }
        }
        
        for sticky in stickies {
            draw_sticky(sticky)
        }

        draw_button(click_me)


        if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
            switch current_page.id {
                case "home_page":
                    current_page = next_page
                case "next_page":
                    current_page = home_page
            }
        }

        // fmt.println("about to check for clicks")
        if rl.IsGestureDetected(rl.Gesture.TAP) {
            now := rl.GetTime()
            time_since_last_click = now - last_click_timestamp
            last_click_timestamp = now 
            
            click_pos := Vector2{rl.GetTouchX(), rl.GetTouchY()}
            is_right := rl.IsMouseButtonPressed(rl.MouseButton.RIGHT)
            mouse_button: string
            if is_right {
                mouse_button = "Right"
            } else {
                mouse_button = "Left"
            }

            // fmt.println(mouse_button, "click detected -- x:", click_pos.x, "y:", click_pos.y, "\nIt has been", time_since_last_click, "seconds since last click event was detected.")
            x_bound: bool = (click_me.position.x < click_pos.x) && (click_pos.x < (click_me.position.x + click_me.size.x))
            y_bound: bool = (click_me.position.y < click_pos.y) && (click_pos.y < (click_me.position.y + click_me.size.y))
            
            if x_bound && y_bound {
                fmt.println("You clicked me!!!")
                
                buf: [4]u8
                new_id := strconv.write_int(buf[:], i64(len(stickies)), 10)

                // make a 300x300 sticky when clicked
                append(&stickies, Sticky{
                    id = strings.clone(new_id),
                    text = strings.clone_to_cstring("sample sticky"),
                    font_size = 12,
                    font_color = rl.BLACK,
                    position = Vector2{MIDX, MIDY},
                    size = Vector2{300, 300},
                    bg_color = rl.YELLOW,
                })

                fmt.println(stickies)
            }
        }

        // fmt.println("about to check for click-drag")
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            click_pos := Vector2{rl.GetTouchX(), rl.GetTouchY()}
            // if we aren't already holding a sticky
            if currently_held == nil && len(stickies) != 0 {
                found := false
                for &s in stickies {
                    // checking if the cursor is over a sticky
                    if found == false {
                        within_x_bounds: bool = (s.position.x < click_pos.x) && (click_pos.x < (s.position.x + s.size.x))
                        within_y_bounds: bool = (s.position.y < click_pos.y) && (click_pos.y < (s.position.y + s.size.y))
                        if within_x_bounds && within_y_bounds {
                            fmt.println("picking up sticky ", s.id)
                            found = true
                            currently_held = &s
                            move_offset.x = currently_held.position.x - click_pos.x
                            move_offset.y = currently_held.position.y - click_pos.y
                            fmt.println("Move offset (x, y): ", move_offset)
                        }
                    }
                }
            } 

            move_held_to.x = click_pos.x + move_offset.x
            move_held_to.y = click_pos.y + move_offset.y
        } else {
            if currently_held != nil {
                fmt.println("dropping sticky ", currently_held.id)
                currently_held = nil
            }
        }

        // dbl_click detection
        if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
            now := rl.GetTime()

            diff := (now - double_click_timestamp)
            within_double_click_limit: bool = (diff <= 0.5)
            
            if within_double_click_limit {
                fmt.println("INFO: Double click detected.")
                // TODO: impl text editing if the double click occurred on an object w/ editable content
            } else {
                double_click_timestamp = now
            }
        }

    }




}