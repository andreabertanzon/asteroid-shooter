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
    perfFrequency: f64 = 0.0,
    renderer: *c.SDL_Renderer = undefined,
    player: Entity = undefined,
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,

    pub fn getTime(self: *Game) f64 {
        return @intToFloat(f64, c.SDL_GetPerformanceCounter()) * 1000 / self.perfFrequency;
    }

    pub fn initGameAssets(self: *Game, rend: *c.SDL_Renderer, pFreq: f64) void {
        self.perfFrequency = pFreq;
        self.renderer = rend;

        const player_texture: ?*c.SDL_Texture = c.IMG_LoadTexture(self.renderer, "src/assets/ship.png");

        // init with starting position
        var destination = c.SDL_Rect{ .x = 20, .y = WINDOW_HEIGHT / 2, .w = undefined, .h = undefined };
        _ = c.SDL_QueryTexture(player_texture, undefined, undefined, &destination.w, &destination.h);

        // reduce the source by 10x
        destination.w = @divTrunc(destination.w * 4, 1);
        destination.h = @divTrunc(destination.h * 4, 1);
        //destination.w = destination.w;
        //destination.h = destination.h;

        self.player = Entity{
            .tex =  player_texture orelse return,
            .dest = destination,
        };
    }
};

const Entity = struct {
    tex: *c.SDL_Texture,
    dest: c.SDL_Rect,
    pub fn movePlayer(self: *Entity, x: f64, y: f64) void {
        var num = @floatToInt(i32, x);
        var numy = @floatToInt(i32, y);
        self.dest.x = std.math.clamp(self.dest.x + num, 0, WINDOW_WIDTH - self.dest.w);
        self.dest.y = std.math.clamp(self.dest.y + numy, 0, WINDOW_HEIGHT - self.dest.h);
    }
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
    
    var game = Game {};
    
    game.initGameAssets(renderer, @intToFloat(f64, perf));

    var frame: usize = 0;
    var start: f64 = 0;
    var end: f64 = 0;

    mainloop: while (true) {
        start = game.getTime();
        // 1. Get Keyboard state
        var state = c.SDL_GetKeyboardState(undefined);

        // 2. Events
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => break :mainloop,
                // c.SDL_KEYDOWN => switch (sdl_event.key.keysym.scancode) {
                //     ESC_KEY => break :mainloop,
                //     else => print("{}", .{sdl_event.key.keysym.scancode}),
                // },
                else => {},
            }
        }
        // 3. Rendering portion
        _ = c.SDL_SetRenderDrawColor(game.renderer, 0xff, 0xff, 0xff, 0xff);
        _ = c.SDL_RenderClear(game.renderer);

        game.left = state[c.SDL_SCANCODE_A] > 0;
        game.right = state[c.SDL_SCANCODE_D] > 0;
        game.up = state[c.SDL_SCANCODE_W] > 0;
        game.down = state[c.SDL_SCANCODE_S] > 0;

        if (state[c.SDL_SCANCODE_ESCAPE] > 0) {
            break :mainloop;
        }

        var delta_motion: f64 = 4;

        if (game.left) {
            game.player.movePlayer(-delta_motion, 0);
        }
        if (game.right) {
            game.player.movePlayer(delta_motion, 0);
        }
        if (game.up) {
            game.player.movePlayer(0, -delta_motion);
        }
        if (game.down) {
            game.player.movePlayer(0, delta_motion);
        }
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
