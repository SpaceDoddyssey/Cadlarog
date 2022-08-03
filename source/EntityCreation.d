module entitycreation;

import ecsd;
import ecsd.events;
import events;
import renderer;
import playermodule;
import guiinfo;

import components;
import components.complex;
import components.ai;
import components.equipslots;

import dplug.math.vector;
import bindbc.sdl;
import bindbc.sdl.image;
import std.stdio;
import std.conv;

static Entity makeEntity(Universe verse, string s, string s2, int x, int y){
    if(s == "Player"){
        MapPos* mp = player.get!MapPos;
        mp.position = vec2i(x, y);
        Transform* t = player.get!Transform;
        t.position = vec2i(x*32, y*32);
            return player;
    }
    Entity ent = Entity(verse.allocEntity);
    ent.add(Transform(vec2i(x*32, y*32)));
    ent.add(PubSub());
    ent.add(MapPos(vec2i(x, y)));
    ent.add(Name(s));
    switch(s){
        case("Door"):{
            ent.add(SpriteRender("sprites/door_closed.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(Door(false, "sprites/door_open.png", "sprites/door_closed.png"));
            ent.add(TileBlock());
            ent.add(Wood());
            break;
        }
        case("Crate"):{
            ent.add(SpriteRender("sprites/crate.png", vec2i(32, 32), SpriteLayer.Door)); 
            ent.add(TileBlock());
            if(s2 != null){
                Contents* c = ent.add(Contents());
                c.addContents(makeEntity(verse, s2, null, x, y));
            }
            ent.add(HP(3));
            ent.add(AttackBait());
            break;
        }
        case("Sword"):{
            ent.add(SpriteRender("sprites/claymore.png", vec2i(32, 32), SpriteLayer.Item));
            ent.add(Metal());
            ent.add(Weapon(Attack(3)));
            ent.add(CanPickUp());
            break;
        }
        case("Shield"):{
            ent.add(SpriteRender("sprites/shield.png", vec2i(32, 32), SpriteLayer.Item));
            ent.add(Wood());
            ent.add(Shield(1));
            ent.add(CanPickUp());
            break;
        }
        case("Slime"):{
            ent.add(SpriteRender("sprites/slime_purple.png", vec2i(32, 32), SpriteLayer.Character));
            ent.add(HP(5));
            ent.add(TileBlock());
            ent.add(SlimeAI());
            ent.add(PrimaryWeaponSlot(Attack(2)));
            ent.add(AttackBait());
            break;
        }
        default:
            break;
    }
    return ent;
}

static Entity makePlayer(Universe verse){
    Entity ent = Entity(verse.allocEntity);
    ent.add(Name("Hero"));
    ent.add(PubSub());
    ent.add(SpriteRender("sprites/playerChar.png", vec2i(32, 32), SpriteLayer.Character));
    ent.add(Transform(vec2i(0, 0)));
    ent.add(MapPos(vec2i(0, 0)));
    ent.add(TileBlock());
    ent.add(HP(10));
    ent.add(PrimaryWeaponSlot(Attack(1)));
    ent.add(ShieldSlot());
    player = ent;
    return ent;
}

@EventSubscriber
void onEntityAttacked(ref EntityEvent!AttackEvent ev)
{
    if(ev.source == player){
        string s = "You deal " ~ to!string(ev.a.damage) ~ " damage to the " ~ *(ev.victim.get!Name);
        addLogMessage(s);
    }
}

@EventSubscriber
void registerComponents(ref UniverseAllocated ev)
{
    registerSimpleComponents(ev.universe);
    registerEquipComponents(ev.universe);
    registerAIComponents(ev.universe);
    registerComplexComponents(ev.universe);
    ev.universe.registerBuiltinComponents;
}