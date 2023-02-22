const std = @import("std");
const print = std.debug.print;
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_image.h"); // adds image.h since sdl cannot load images other than bmp
});

const WINDOW_FLAGS = c.SDL_WINDOW_SHOWN;
const TARGET_DELTA_TIME: f64 = @intToFloat(f64, 1000) / @intToFloat(f64, 60);
const ESC_KEY = 41;
const WINDOW_WIDTH:i32 = 1600;
const WINDOW_HEIGHT:i32 = 960;
const PLAYER_SPEED :f64 = 500.0;
const LASER_SPEED :f64 = 700.0;

const Game = struct {
    perfFrequency: f64 = 0.0,
    renderer: *c.SDL_Renderer = undefined,
    player: Entity = undefined,
    laser: Entity = undefined,
    left: bool = false,
    right: bool = false,
    up: bool = false,
    down: bool = false,
    fire:bool = false,

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

        destination.w = @divTrunc(destination.w * 4, 1);
        destination.h = @divTrunc(destination.h * 4, 1);

        self.player = Entity{
            .tex =  player_texture orelse return,
            .dest = destination,
            .health = 10,
        };

        var destination2 = c.SDL_Rect{ .x = 20, .y = WINDOW_HEIGHT / 2, .w = 0, .h = 0 };
        const laser_texture: ?*c.SDL_Texture = c.IMG_LoadTexture(self.renderer, "src/assets/shot.png");
        _ = c.SDL_QueryTexture(laser_texture, undefined, undefined, &destination2.w, &destination2.h);

        destination2.w = @divTrunc(destination2.w, 1);
        destination2.h = @divTrunc(destination2.h, 1);

        self.laser = Entity {
            .tex = laser_texture orelse return,
            .dest = destination2,
            .health = 0,
        };
    }
};

const Entity = struct {
    tex: *c.SDL_Texture,
    dest: c.SDL_Rect,
    health: u32,
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

    //defer c.SDL_Quit(); //TODO: check why this hangs? the other defer all work correctly.

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

    const t = TARGET_DELTA_TIME;
    print("{}", .{t});
    const l = LASER_SPEED;
    const laserMotion = getDeltaMotion(l);
    const p = @floatToInt(c_int, laserMotion);

    mainloop: while (true) {
        start = game.getTime();
        // 1. Get Keyboard state
        var state = c.SDL_GetKeyboardState(undefined);

        // 2. Events
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => {
                    print("closing", .{});
                    break :mainloop;
                },
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
        game.fire = state[c.SDL_SCANCODE_SPACE] > 0;

        if (state[c.SDL_SCANCODE_ESCAPE] > 0) {
            break :mainloop;
        }

        var delta_motion: f64 = getDeltaMotion(PLAYER_SPEED);

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

        if(game.fire and game.laser.health == 0){
            game.laser.dest.x = game.player.dest.x + 30;
            game.laser.dest.y = game.player.dest.y;
            game.laser.health = 1;
        }

        if(game.laser.dest.x >= WINDOW_WIDTH and game.laser.health > 0){
            game.laser.health = 0;
            game.laser.dest.x = game.player.dest.x;
        }

        if(game.laser.health > 0){
            // var motion = getDeltaMotion(LASER_SPEED);
            
            game.laser.dest.x = game.laser.dest.x + p;
            _ = c.SDL_RenderCopy(game.renderer, game.laser.tex, null, &game.laser.dest);
        }

       // enforcing a certain framerate.
        end = game.getTime();
        while (end - start < TARGET_DELTA_TIME) {
            end = game.getTime();
        }
        c.SDL_RenderPresent(game.renderer);
        frame += 1;
    }
    print("program ends", .{});
    return;
}

pub fn getDeltaMotion(speed: f64) f64 {
    const t = TARGET_DELTA_TIME;
    var result : f64 = speed * t;
    result = result / 1000;
    return result;
}
