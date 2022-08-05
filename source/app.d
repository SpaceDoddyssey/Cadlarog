module app;

import events;
import app;
import ecsd;
import ecsd.events;
import ecsd.userdata;
import game;
import renderer;
import entitycreation;
import perf;
import input;
import components;
import components.complex;
import playermodule;
import set;
import randommodule;
import levelmap;

import std;
import std.experimental.logger;
import dplug.math.vector;
import bindbc.sdl;

alias ShouldExit = Flag!"ShouldExit";

void main()
{
    debug sharedLog.logLevel = LogLevel.all;
    else sharedLog.logLevel = LogLevel.info;

    subscribeFunctions();

    writeln("App starting");
    init();
/*    import std: array, sort, each;
scope(exit) Perf
    .times
    .byKeyValue
    .array
    .sort!"a.value > b.value"
    .each!(p => writeln(p.key, " => ", p.value));*/
}

void subscribeFunctions(){
    writeln("Subscribing functions");
    subscribe(&placeEntity);
writeln(__LINE__);
    subscribe(&gameInit);
writeln(__LINE__);
    subscribe(&rendererInit);
writeln(__LINE__);
    subscribe(&appShutdown);
writeln(__LINE__);
    subscribe(&renderLoop);
writeln(__LINE__);
    subscribe(&cameraMove);
writeln(__LINE__);
    subscribe(&onEntityAttacked);
writeln(__LINE__);
    subscribe(&registerComponents);
writeln(__LINE__);
    subscribe(&pickUp);
writeln(__LINE__);
    subscribe(&playerMove);
writeln(__LINE__);
    subscribe(&processEvent);
writeln(__LINE__);
    subscribe(&controlHandling);
writeln(__LINE__);
}

void init(){
    publish!AppStartup;
    loop();
    publish!FinishStruct;
}

void loop(){
/*    auto perf = Perf(null);
    double lastFrame = nowSeconds;
    double fpsAccum = 0;
    int frames;
*/    
    while(true) {
//        const now = nowSeconds;
//        const frameDelta = now - lastFrame;
//        lastFrame = now;
  
        publish!LoopStruct;
        if (processEvents() == ShouldExit.yes){
            break;
        }
//        frames++;
        
/*
        fpsAccum += frameDelta;
        if(fpsAccum >= 1) {
            trace("%d fps", frames);
            fpsAccum -= 1;
            frames = 0;
        }
*/
    }
}

double nowSeconds() {
    return SDL_GetTicks() / 1000.0;
}

ShouldExit processEvents()
{
    auto perf = Perf(null);
    SDL_Event event = void;
    while(SDL_PollEvent(&event)) switch(event.type)
    {
        case SDL_QUIT:
            return ShouldExit.yes;
        case SDL_KEYDOWN:
            switch(event.key.keysym.sym)
            {
                case SDLK_ESCAPE:
                    return ShouldExit.yes;
                default:
            }
            goto default;
        default:
            publish(SDLEvent(&event));
    }
    
    return ShouldExit.no;
}