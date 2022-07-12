module components;

import dplug.math.vector;

import ecsd;
import std.stdio;
import renderer;
import events;
import std.stdio;
struct HP{
    int curHP, maxHP, damRed = 0;
    Entity ent = void;
    this(int h){
        curHP = maxHP = h;
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&receiveAttack);
    }
    public void setDR(int d){ damRed = d; }
    public void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        //handle death - expand this in general ----------------- 
    }
    public void receiveAttack(Entity e, ref Attack a){
        int d = a.damage;
        if (d > damRed) { curHP -= (d - damRed); } 
    }
}

struct Attack{
    int damage;
}

struct Door{
    bool isOpen;
    string openSprite, closedSprite;
    Entity ent = void;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&doorOpen);
        (ent.get!PubSub).subscribe(&doorClose);
    }
    void doorOpen(Entity e, ref OpenEvent o){
        if(!isOpen) { 
            isOpen = true; 
            (ent.get!SpriteRender).path = openSprite;
            ent.remove!TileBlock;
        } else { writeln("Door is already open!"); }
    }
    void doorClose(Entity e, ref CloseEvent c){
        if(isOpen) { 
            isOpen = false; 
            (ent.get!SpriteRender).path = closedSprite;
            ent.add!TileBlock;
        } else { writeln("Door is already closed!"); }
    }
}

struct Contents{
    Entity[] contents;
    alias contents this;
}

struct Transform{ vec2i position; alias position this; }
struct MapPos{ vec2i position; alias position this; }
struct AttackBait{}
struct TileBlock{}
struct Wood{}
struct Metal{}

static void registration(Universe verse){
    verse.registerBuiltinComponents;
    verse.registerComponent!Transform;
    verse.registerComponent!SpriteRender;
    verse.registerComponent!HP;
    verse.registerComponent!MapPos;
    verse.registerComponent!Door;
    verse.registerComponent!Wood;
    verse.registerComponent!Metal;
    verse.registerComponent!Contents;
    verse.registerComponent!TileBlock;
    verse.registerComponent!AttackBait;
    verse.registerComponent!Attack;
}
/*
    void onComponentAdded(Universe, EntityID)
    {
        damage = uniform(5, 25);
    }*/