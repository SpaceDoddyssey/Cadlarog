module app;

import ecsd;
import events;
import renderer;
import perf;

import std;
import std.experimental.logger;
import dplug.math.vector;
import bindbc.sdl;

alias ShouldExit = Flag!"ShouldExit";

void main()
{
    debug sharedLog.logLevel = LogLevel.all;
    else sharedLog.logLevel = LogLevel.info;

    init();
    //import std: array, sort, each;
/*scope(exit) Perf
    .times
    .byKeyValue
    .array
    .sort!"a.value > b.value"
    .each!(p => writeln(p.key, " => ", p.value));*/
}

void init(){
    publish!AppStartup;
    loop();
    publish!FinishStruct;
}

void loop(){
    //auto perf = Perf(null);
    double lastFrame = nowSeconds;
    double fpsAccum = 0;
    int frames;
    
    while(true) {
/*        const now = nowSeconds;
        const frameDelta = now - lastFrame;
        lastFrame = now;
*/       
        publish!LoopStruct;
        if (processEvents() == ShouldExit.yes){
            break;
        }
  /*      frames++;
        
        fpsAccum += frameDelta;
        if(fpsAccum >= 1) {
            trace("%d fps", frames);
            fpsAccum -= 1;
            frames = 0;
        }*/
    }
}

double nowSeconds() {
    return SDL_GetTicks() / 1000.0;
}


//============================================================================

ShouldExit processEvents()
{
    //auto perf = Perf(null);
    SDL_Event event = void;
    while(SDL_PollEvent(&event)) switch(event.type)
    {
        case SDL_QUIT:
            return ShouldExit.yes;
        default:
            publish(SDLEvent(&event));
        /*
        case SDL_QUIT:
            return ShouldExit.yes;
        case SDL_KEYDOWN:
            switch(event.key.keysym.sym)
            {
                case SDLK_ESCAPE:
                    return ShouldExit.yes;
                case SDLK_LEFT:
                    publish(Move(Dir.Left)); break;
                case SDLK_RIGHT:
                    publish(Move(Dir.Right)); break;
                case SDLK_UP:
                    publish(Move(Dir.Up)); break;
                case SDLK_DOWN:
                    publish(Move(Dir.Down)); break;
                default:
            }
            goto default;
        default:*/
    }
    
    return ShouldExit.no;
}