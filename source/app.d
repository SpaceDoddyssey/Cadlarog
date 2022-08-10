module app;

import events;
import app;
import ecsd;
import ecsd.events;
import ecsd.userdata;
import game;
import rendermodule;
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
    subscribe(&onEntityAlloc);
    subscribe(&placeEntity);
    subscribe(&gameInit);
    subscribe(&rendererInit, int.max >> 1);
    subscribe(&appShutdown);
    subscribe(&renderLoop);
    subscribe(&cameraMove);
    //subscribe(&onEntityAttacked);
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