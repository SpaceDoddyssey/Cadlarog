module app;

import app;
import components;
import components.complex;
import ecsd;
import ecsd.events;
import ecsd.userdata;
import entitycreation;
import events;
import game;
import input;
import levelmap;
import perf;
import playermodule;
import randommodule;
import rendermodule;
import set;

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

    writeln("App startup");
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
    subscribe(&onEntityAlloc);
    subscribe(&placeEntity);
    subscribe(&gameInit);
    subscribe(&rendererInit, int.max >> 1);
    subscribe(&appShutdown);
    subscribe(&renderLoop);
    subscribe(&cameraMove);
    subscribe(&registerComponents);
    subscribe(&pickUp);
    subscribe(&playerMove);
    subscribe(&processEvent);
    subscribe(&controlHandling);
}

void onEntityAlloc(ref EntityAllocated ev) {
  if(!ev.entity.has!PubSub) ev.entity.add!PubSub;
}

void init(){
    publish!AppStartup;
    writeln("finished setup");
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