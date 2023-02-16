const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("SDL.h");
});

const WINDOW_FLAGS = c.SDL_WINDOW_SHOWN;
const TARGET_DT = 1000 / 60;
const ESC_KEY = 41;

const Game = struct {
    perfFrequency:f64,
    renderer:*c.SDL_Renderer,
    pub fn getTime(self:*Game) f64{
        return @intToFloat(f64, c.SDL_GetPerformanceCounter()) * 1000 / self.perfFrequency;
    }
};

pub fn main() anyerror!void {
    _ = c.SDL_Init(c.SDL_INIT_VIDEO);
    defer c.SDL_Quit();

    var window = c.SDL_CreateWindow("asteroid shooter", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, 640, 400, WINDOW_FLAGS);
    defer c.SDL_DestroyWindow(window);

    var renderer = c.SDL_CreateRenderer(window, 0, c.SDL_RENDERER_PRESENTVSYNC) orelse return;
    defer c.SDL_DestroyRenderer(renderer);
    var perf = c.SDL_GetPerformanceFrequency();
    var game = Game{
        .renderer = renderer,
        .perfFrequency = @intToFloat(f64,perf)
    };
    print("{}",.{game.perfFrequency});
    var frame: usize = 0;

    var start: f64 = 0;
    var end: f64 = 0;

    mainloop: while (true) {
        start = game.getTime();
        // 1. Get Keyboard state
//        var state = c.SDL_GetKeyboardState(null);

        // 2. Events
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => break :mainloop,
                c.SDL_KEYDOWN => switch(sdl_event.key.keysym.scancode){
                    ESC_KEY => break :mainloop,
                    else => print("{}", .{sdl_event.key.keysym.scancode}),
                }, 
                else => {},
            }
        }

        // 3. Rendering portion
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0xff, 0xff, 0xff, 0xff);
        _ = c.SDL_RenderClear(game.renderer);
        var rect = c.SDL_Rect{ .x = 0, .y = 0, .w = 60, .h = 60 };
        const a = 0.06 * @intToFloat(f32, frame);
        const t = 2 * std.math.pi / 3.0;
        const r = 100 * @cos(0.1 * a);
        rect.x = 290 + @floatToInt(i32, r * @cos(a));
        rect.y = 170 + @floatToInt(i32, r * @sin(a));
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0xff, 0, 0, 0xff);
        _ = c.SDL_RenderFillRect(game.renderer, &rect);
        rect.x = 290 + @floatToInt(i32, r * @cos(a + t));
        rect.y = 170 + @floatToInt(i32, r * @sin(a + t));
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0, 0xff, 0, 0xff);
        _ = c.SDL_RenderFillRect(game.renderer, &rect);
        rect.x = 290 + @floatToInt(i32, r * @cos(a + 2 * t));
        rect.y = 170 + @floatToInt(i32, r * @sin(a + 2 * t));
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0, 0, 0xff, 0xff);
        _ = c.SDL_RenderFillRect(game.renderer, &rect);

        // enforcing a certain framerate.
        end = game.getTime();
        while(end - start < TARGET_DT){
            end = game.getTime();
        }
        c.SDL_RenderPresent(game.renderer);
        frame += 1;
    }
}