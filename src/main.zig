const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h"); // adds image.h since sdl cannot load images other than bmp
});

const WINDOW_FLAGS = c.SDL_WINDOW_SHOWN;
const TARGET_DT = 1000 / 60;
const ESC_KEY = 41;
const WINDOW_WIDTH = 1600;
const WINDOW_HEIGHT = 960;

const Game = struct {
    perfFrequency: f64,
    renderer: *c.SDL_Renderer,
    player: Entity = undefined,
    pub fn getTime(self: *Game) f64 {
        return @intToFloat(f64, c.SDL_GetPerformanceCounter()) * 1000 / self.perfFrequency;
    }
};

const Entity = struct {
    tex: *c.SDL_Texture,
    dest: c.SDL_Rect,
};

pub fn main() anyerror!void {
    //TODO: Check how to handle errors properly when calling c libraries!
    _ = c.SDL_Init(c.SDL_INIT_VIDEO); // Initializes SDL library
    _ = c.IMG_Init(c.IMG_INIT_PNG); // initializes PNG reading.

    defer c.SDL_Quit();

    var window = c.SDL_CreateWindow("asteroid shooter", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_FLAGS);
    defer c.SDL_DestroyWindow(window);

    var renderer = c.SDL_CreateRenderer(window, 0, c.SDL_RENDERER_PRESENTVSYNC) orelse return;
    defer c.SDL_DestroyRenderer(renderer);

    var perf = c.SDL_GetPerformanceFrequency();
    var game = Game{ .renderer = renderer, .perfFrequency = @intToFloat(f64, perf) };
    print("{}", .{game.perfFrequency});

    // load assests
    const player_texture: *c.SDL_Texture = c.IMG_LoadTexture(game.renderer, "src/assets/player.png") orelse {
        // var p:[*c]const u8 = undefined;
        // p=c.SDL_GetError();
        // print("Error here, {any}",.{p});
        return;
    };
    print("{any}", .{player_texture});

    // init with starting position
    var destination = c.SDL_Rect{ .x = 20, .y = WINDOW_HEIGHT / 2, .w = WINDOW_WIDTH / 2, .h = WINDOW_HEIGHT / 2 };
    _ = c.SDL_QueryTexture(player_texture, undefined, undefined, &destination.w, &destination.h);

    // reduce the source by 10x
    destination.w = @divTrunc(destination.w, 1);
    destination.h = @divTrunc(destination.h, 1);

    game.player = Entity{
        .tex = player_texture,
        .dest = destination,
    };

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
                c.SDL_KEYDOWN => switch (sdl_event.key.keysym.scancode) {
                    ESC_KEY => break :mainloop,
                    else => print("{}", .{sdl_event.key.keysym.scancode}),
                },
                else => {},
            }
        }

        // 3. Rendering portion
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0xff, 0xff, 0xff, 0xff);
        _ = c.SDL_RenderClear(game.renderer);
        // var rect = c.SDL_Rect{ .x = 0, .y = 0, .w = 60, .h = 60 };
        // const a = 0.06 * @intToFloat(f32, frame);
        // const t = 2 * std.math.pi / 3.0;
        // const r = 100 * @cos(0.1 * a);
        // rect.x = 290 + @floatToInt(i32, r * @cos(a));
        // rect.y = 170 + @floatToInt(i32, r * @sin(a));
        // _ = c.SDL_SetRenderDrawColor(game.renderer, 0xff, 0, 0, 0xff);
        // _ = c.SDL_RenderFillRect(game.renderer, &rect);
        // rect.x = 290 + @floatToInt(i32, r * @cos(a + t));
        // rect.y = 170 + @floatToInt(i32, r * @sin(a + t));
        // _ = c.SDL_SetRenderDrawColor(game.renderer, 0, 0xff, 0, 0xff);
        // _ = c.SDL_RenderFillRect(game.renderer, &rect);
        // rect.x = 290 + @floatToInt(i32, r * @cos(a + 2 * t));
        // rect.y = 170 + @floatToInt(i32, r * @sin(a + 2 * t));
        // _ = c.SDL_SetRenderDrawColor(game.renderer, 0, 0, 0xff, 0xff);
        // _ = c.SDL_RenderFillRect(game.renderer, &rect);
        _ = c.SDL_RenderCopy(game.renderer, game.player.tex, null, &game.player.dest);
        // the third argument -> which part of the player sheet to grab and display!

        // enforcing a certain framerate.
        end = game.getTime();
        while (end - start < TARGET_DT) {
            end = game.getTime();
        }
        c.SDL_RenderPresent(game.renderer);
        frame += 1;
    }
}
