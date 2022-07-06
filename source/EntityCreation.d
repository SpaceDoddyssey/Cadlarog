module entitycreation;

import ecsd;
import events;
import renderer;
import game;
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
    cameraXOffset = x - 15;
    cameraYOffset = y - 10;
    player = ent;
    return ent;
}

struct Transform{
    vec2i position;
}

struct HP{
    int curHP, maxHP, damRed = 0;
    this(int h){
        curHP = maxHP = h;
    }
    public void setDR(int d){ damRed = d; }
    public void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        //handle death - expand this in general ----------------- 
    }
}

struct SpriteRender{
    private:
        SDL_Texture *texture;
        string pathString;
    public:
        SpriteLayer layer;
        vec2i size;
        this(string p, vec2i s, SpriteLayer l){
            path = p; size = s; layer = l;
        }
        void path(string p){
            pathString = p;
            texture = getTexture(p);
        }
        string path(){
            return pathString;
        }
}