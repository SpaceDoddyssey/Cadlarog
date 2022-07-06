module game;

import app;
import levelmap;
import events;
import renderer;

import std.stdio;
import ecsd;

Entity player = void;

shared static this(){
  subscribe(&init);
  subscribe(&loop);
  subscribe(&move);
}

void init(ref AppStartup s){ 
  LevelMap lm = levelinit(50, 50);
  Universe uni = lm.verse;
    writeln("init");
}

void loop(ref LoopStruct l){
}

void move(ref Move m){
  switch(m.dir){
    case Dir.Left:
        cameraXOffset -= 1; break;
    case Dir.Right:
        cameraXOffset += 1; break;
    case Dir.Up:
        cameraYOffset -= 1; break;
    case Dir.Down:
        cameraYOffset += 1; break;
    default:
  }
}
