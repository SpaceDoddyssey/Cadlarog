module entitycreation;

import ecsd;
import events;
import renderer;
import components;

import dplug.math.vector;
import bindbc.sdl;
import bindbc.sdl.image;

static Entity makeEntity(Universe verse, string s, int x, int y){
    Entity ent = Entity(verse.allocEntity);
    ent.add(Transform(vec2i(x*32, y*32)));
    switch(s){
        case("Door"):{
            ent.add(SpriteRender("sprites/door_closed.png", vec2i(32, 32), SpriteLayer.Door)); break;
        }
        case("Crate"):{
            ent.add(SpriteRender("sprites/crate.png", vec2i(32, 32), SpriteLayer.Door)); break;
        }
        default:
            break;
    }
    return ent;
}

static Entity makePlayer(Universe verse, int x, int y){
    Entity ent = Entity(verse.allocEntity);
    ent.add(SpriteRender("sprites/playerChar.png", vec2i(32, 32), SpriteLayer.Character));
    ent.add(Transform(vec2i(x*32, y*32)));
    ent.add(MapPos(vec2i(x, y)));
    ent.add(HP(10));
    cameraXOffset = x - 15;
    cameraYOffset = y - 10;
    import game: player;
    player = ent;
    return ent;
}