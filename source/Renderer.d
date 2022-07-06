module renderer;

import ecsd;
//import game;
import events;
import entitycreation;
import perf;

import std;
import std.experimental.logger;
import dplug.math.vector;
import bindbc.sdl;
import bindbc.sdl.image;
import std.stdio;

SDL_Window* window;
SDL_Renderer* renderer;
int cameraXOffset = 15, cameraYOffset = -10;

ComponentCache!(Transform, SpriteRender) spriteDrawables;
SDL_Texture*[string] textureCache;
Sprite[] sprites;

shared static this(){
  subscribe(&init);
  subscribe(&loop);
  subscribe(&appShutdown);
}

enum SpriteLayer{
    Background = -1,
    Floor = 0,
    Door = 1,
    Item = 2,
    Character = 3
}

void init(ref AppStartup s){ 
    //Create the window
//============================================================================
    //This code provided by Steven Dwy, me@yoplitein.net

    SDLSupport sdlVer = loadSDL();
    if(sdlVer != sdlSupport)
    {
        if(sdlVer == SDLSupport.noLibrary)
            fatalf("could not load libSDL");
        else if(sdlVer == SDLSupport.badLibrary)
            warning("libSDL seems to be outdated");
    }
    SDLImageSupport sdlImageVer = loadSDLImage();
    if(sdlImageVer != sdlImageSupport)
    {
        if(sdlImageVer == SDLImageSupport.noLibrary)
            fatalf("could not load image libSDL");
        else if(sdlImageVer == SDLImageSupport.badLibrary)
            warning("Image libSDL seems to be outdated");
    }
    
    SDL_version ver = void;
    SDL_GetVersion(&ver);
    infof("loaded SDL version %(%d.%)", [ver.tupleof]);
    
    if(SDL_Init(SDL_INIT_EVENTS | SDL_INIT_VIDEO) != 0)
        fatalf("failed to initialize SDL: %s", SDL_GetError().fromStringz);
    
    enum vpWidth = 1280;
    enum vpHeight = 720;

    window = SDL_CreateWindow(
        "Roguelike",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        vpWidth, vpHeight,
        SDL_WINDOW_SHOWN | SDL_WINDOW_INPUT_FOCUS
    );
    if(window is null) fatalf("failed to open window: %s", SDL_GetError().fromStringz);
    
    renderer = SDL_CreateRenderer(
        window,
        -1,
        SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE
    );
    if(renderer is null) fatalf("failed to create renderer: %s", SDL_GetError().fromStringz);
}

void appShutdown(ref FinishStruct f){
    SDL_Quit();
    SDL_DestroyWindow(window);
}

void loop(ref LoopStruct l){
    auto perf = Perf(null);
    //Render the window
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

    if(spriteDrawables.refresh){
        spriteDrawables.entities.sort!"a.spriteRender.layer < b.spriteRender.layer";
    }
    //writeln("xOffset: ", cameraXOffset);
    foreach(ent, ref transform, ref sprite; spriteDrawables){
        SDL_Rect rect = {
            x: transform.position.x - cameraXOffset * 32,
            y: transform.position.y - cameraYOffset * 32,
            w: sprite.size.x,
            h: sprite.size.y,
        };
        SDL_RenderCopy(
            renderer,
            textureCache[sprite.path],
            null,
            &rect,
        );
    }
    
    SDL_RenderPresent(renderer);
}

class Sprite{
    SDL_Texture* tex;
    SDL_Rect rect;
    this(SDL_Texture* tex, int w, int h)
    {
        this.tex = tex;
        rect = SDL_Rect(0, 0, w, h);
    }
    void setPosition(int x, int y)
    {
        rect.x = x;
        rect.y = y;
    }
}

Sprite registerSprite(Sprite s, string str, int x, int y){
    SDL_Texture *texture = getTexture(str);
    s.tex = texture;
    s.rect.x = 32; s.rect.y = 32;
    s.setPosition(x, y);
    sprites ~= s;
    return s;
}

SDL_Texture* getTexture(string path)
{
    auto ptr = path in textureCache;
    if(ptr !is null)
        return *ptr;
    return textureCache[path] = loadTextureFromImage(path);
}

SDL_Texture* loadTextureFromImage(string path)
{
    auto perf = Perf(null);
    import std.string: toStringz; // D's string type to char*

    auto surface = IMG_Load(path.toStringz);
    if(surface is null) fatal("Could not load texture at ", path);
    scope(exit) SDL_FreeSurface(surface);
    return SDL_CreateTextureFromSurface(renderer, surface);
}