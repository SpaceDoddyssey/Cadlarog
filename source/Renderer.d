module rendermodule;

import components;
import components.complex;
import ecsd;
import events;
import game;
import guimodule;
import perf;

import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.sdl.ttf;
import dplug.math.vector;
import std;
import std.conv;
import std.experimental.logger;
import std.stdio;

SDL_Window* window;
SDL_Renderer* renderer;
float cameraXOffset; 
float cameraYOffset;
float zoomFactor = 1.0;

HP* playerHP;
SDL_Rect healthRect;
int maxHealthWidth = 150;
TextBox hpReadout;
SavePopup savePopup;
LoadPopup loadPopup;

ComponentCache!(Transform, SpriteRender) spriteDrawables;
SDL_Texture*[string] textureCache;

enum vpWidth = 1280;
enum vpHeight = 720;

enum SpriteLayer{
    Background = -1,
    Floor = 0,
    Door = 1,
    Item = 2,
    Character = 3
}

struct SpriteRender{
    private:
        SDL_Texture *texture;
    public:
        string pathString;
        bool enabled;
        SpriteLayer layer;
        vec2i size;
        this(string p, vec2i s, SpriteLayer l){
            path = p; size = s; layer = l; enabled = true;
        }
        void path(string p){
            pathString = p;
            texture = getTexture(p);
        }
        string path(){
            return pathString;
        }
}

void rendererInit(ref AppStartup s){ 
    //Load general SDL library
    SDLSupport sdlVer;
    version(Win32)
        sdlVer = loadSDL("SDL2_x86.dll");
    else
        sdlVer = loadSDL();
    if(sdlVer != sdlSupport)
    {
        if(sdlVer == SDLSupport.noLibrary)
            fatalf("could not load libSDL");
        else if(sdlVer == SDLSupport.badLibrary)
            warning("libSDL seems to be outdated");
    }
    //Load SDL text library
    SDLTTFSupport sdlTTFVer;
    version(Win32)
        sdlTTFVer = loadSDLTTF("SDL2_ttf_x86.dll");
    else
        sdlTTFVer = loadSDLTTF();
    if(sdlTTFVer != sdlTTFSupport)
    {
        if(sdlTTFVer == SDLTTFSupport.noLibrary)
            fatalf("could not load ttf libSDL");
        else if(sdlTTFVer == SDLTTFSupport.badLibrary)
            warning("ttf libSDL seems to be outdated");
    }
    //Load SDL image library
    SDLImageSupport sdlImageVer;
    version(Win32)
        sdlImageVer = loadSDLImage("SDL2_x86.dll");
    else
        sdlImageVer = loadSDLImage();
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

    if(IMG_Init(IMG_INIT_PNG) != IMG_INIT_PNG)
        fatalf("failed to initialize SDL_Image: %s", SDL_GetError().fromStringz);
    
    //Create window
    window = SDL_CreateWindow(
        "Cadlarog",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        vpWidth, vpHeight,
        SDL_WINDOW_SHOWN | SDL_WINDOW_INPUT_FOCUS
    );
    if(window is null) fatalf("failed to open window: %s", SDL_GetError().fromStringz);
    SDL_Surface* icon = IMG_Load("icon.png");
    SDL_SetWindowIcon(window, icon);
    SDL_FreeSurface(icon);

    renderer = SDL_CreateRenderer(
        window,
        -1,
        SDL_RENDERER_PRESENTVSYNC | SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE
    );
    if(renderer is null) fatalf("failed to create renderer: %s", SDL_GetError().fromStringz);

    //Initialize text rendering
    if(TTF_Init() != 0)
        fatalf("failed to initialize SDL_TTF: %s", SDL_GetError().fromStringz);

    curFont = TTF_OpenFont(fontPath.toStringz(), fontSize);

    //Init saving popups
    savePopup = SavePopup(true);
    loadPopup = LoadPopup(true);

/*
    healthRect.x = 200;
    healthRect.y = vpHeight - 29;
    healthRect.w = maxHealthWidth;
    healthRect.h = 26;
    
    hpReadout = TextBox("");
*/
}

void appShutdown(ref FinishStruct f){
    TTF_CloseFont(curFont);
    TTF_Quit();
    SDL_Quit();
    SDL_DestroyWindow(window);
}

void renderLoop(ref LoopStruct l){
//    auto perf = Perf(null);
//Render the window
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);

//Sprite rendering
    if(spriteDrawables.refresh()){
        spriteDrawables.entities.sort!"a.spriteRender.layer < b.spriteRender.layer";
    }
    foreach(ent, ref transform, ref sprite; spriteDrawables){
        if(!sprite.enabled) continue;
        SDL_Rect rect = {
            x: cast(int)((transform.position.x - cast(int)cameraXOffset * 32) / zoomFactor),
            y: cast(int)((transform.position.y - cast(int)cameraYOffset * 32) / zoomFactor),
            w: cast(int)(sprite.size.x / zoomFactor),
            h: cast(int)(sprite.size.y / zoomFactor),
        };
        SDL_RenderCopy(
            renderer,
            getTexture(sprite.pathString),
            null,
            &rect,
        );
    }

//Text rendering
    foreach(i, ref mess; messages){
        SDL_Rect dstrect = { 4, 4 + cast(int)i*(mess.textHeight + 2), mess.textWidth, mess.textHeight };
        SDL_RenderCopy(renderer, mess.texture, null, &dstrect);
    }

//Render health bar
/*    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 0);
    SDL_RenderDrawRect(renderer, &healthRect);
    SDL_RenderFillRect(renderer, &healthRect);

    SDL_Surface* surface = TTF_RenderText_Shaded(curFont, "HP:" ~ , white);
    hpReadout.texture = SDL_CreateTextureFromSurface(renderer, surface);
    SDL_QueryTexture(mess.texture, null, null, &mess.textWidth, &mess.textHeight);
    mess.initialized = true;
    SDL_FreeSurface(surface);
*/
    SDL_RenderPresent(renderer);
}

void showSavePopup(){
    int w = savePopup.textWidth;
    int h = savePopup.textHeight;
    SDL_Rect dstrect = { vpWidth / 2 - w/2, vpHeight / 2 - h/2, w, h};
    SDL_RenderCopy(renderer, savePopup.texture, null, &dstrect);
    SDL_RenderPresent(renderer);
}

void showLoadPopup(){
    int w = loadPopup.textWidth;
    int h = loadPopup.textHeight;
    SDL_Rect dstrect = { vpWidth / 2 - w/2, vpHeight / 2 - h/2, w, h};
    SDL_RenderCopy(renderer, loadPopup.texture, null, &dstrect);
    SDL_RenderPresent(renderer);
}

void cameraMove(ref CameraMove m){
  import rendermodule: cameraXOffset, cameraYOffset;
  switch(m.dir){
    case Dir.Left:
        cameraXOffset -= 0.3; break;
    case Dir.Right:
        cameraXOffset += 0.3; break;
    case Dir.Up:
        cameraYOffset -= 0.3; break;
    case Dir.Down:
        cameraYOffset += 0.3; break;
    default:
  }
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

    auto surface = IMG_Load(path.toStringz());
    if(surface is null) fatalf(
"Could not load texture at %s (SDL error: `%s`)", path, SDL_GetError().fromStringz);    
scope(exit) SDL_FreeSurface(surface);
    if(surface is null){

        surface = IMG_Load("sprites/Empty.png");
    }
    return SDL_CreateTextureFromSurface(renderer, surface);
}