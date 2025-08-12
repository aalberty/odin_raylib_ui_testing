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

    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(WIDTH, HEIGHT, TITLE)
    defer rl.CloseWindow() 
    rl.SetTargetFPS(60)

    current_page: Page = home_page

    for !rl.WindowShouldClose() {

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground(current_page.bg_color)
        tw := rl.MeasureText(current_page.message, FONT_SIZE)
        x := i32(MIDX - tw/2)
        y := i32(MIDY - FONT_SIZE/2)

        rl.DrawText(current_page.message, x, y, FONT_SIZE, current_page.font_color)

        // update sticky location if there's one currently held
        if currently_held != nil {
            // TODO: don't let it move off of the window bounds
            // AKA ignore move_held_to values that are outside of window bounds;
            // this approach will make it so that even if the mouse is dragged to an invalid
            // location, as soon as it comes back within the bounds, then the sticky pos will
            // start updating again
            currently_held.position.x = move_held_to.x
            currently_held.position.y = move_held_to.y
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
            click_pos := Vector2{rl.GetTouchX(), rl.GetTouchY()}
            fmt.println("click detected -- x: ", click_pos.x, " y: ", click_pos.y)
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
    }
}