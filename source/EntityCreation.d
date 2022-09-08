module entitycreation;

import bindbc.sdl;
import bindbc.sdl.image;
import dplug.math.vector;
import std.conv;
import std.stdio;

import ecsd;
import ecsd.events;
import ecsd.storage;

import events;
import guimodule;
import playermodule;
import rendermodule;

import components;
import components.ai;
import components.complex;
import components.equipslots;
import components.traps;

static Entity makeEntity(Universe verse, string s, string s2){
    Entity ent = Entity(verse.allocEntity);
    ent.add(Transform(vec2i(0, 0)));
    ent.add(MapPos(vec2i(0, 0)));
    switch(s){
        case("Tile"):{ return ent; }
        case("door"):{
            ent.add(SpriteRender("sprites/door_closed.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(Door(false, "sprites/door_open.png", "sprites/door_closed.png"));
            ent.add(TileBlock());
            ent.add(Wood());
            ent.add(Name(s));
            break;
        }
        case("crate"):{
            ent.add(SpriteRender("sprites/crate.png", vec2i(32, 32), SpriteLayer.Door)); 
            ent.add(TileBlock());
            if(s2 != null){
                Contents* c = ent.add(Contents());
                Entity e = makeEntity(verse, s2, null);
                c.addContents(e);
            }
            ent.add(HP(3));
            ent.add(AttackBait());
            ent.add(Name(s));
            break;
        }
        case("sword"):{
            ent.add(SpriteRender("sprites/claymore.png", vec2i(32, 32), SpriteLayer.Item));
            ent.add(Metal());
            ent.add(Weapon(Attack(3)));
            ent.add(CanPickUp());
            ent.add(Name(s));
            break;
        }
        case("shield"):{
            ent.add(SpriteRender("sprites/shield.png", vec2i(32, 32), SpriteLayer.Item));
            ent.add(Wood());
            ent.add(Shield(1));
            ent.add(CanPickUp());
            ent.add(Name(s));
            break;
        }
        case("slime_purple"):{
            ent.add(SpriteRender("sprites/slime_purple.png", vec2i(32, 32), SpriteLayer.Character));
            ent.add(HP(6));
            ent.add(TileBlock());
            ent.add(AISlimePurple());
            ent.add(PrimaryWeaponSlot(Attack(2)));
            ent.add(AttackBait());
            ent.add(Name("purple slime"));
            break;
        }
        case("slime_green"):{
            ent.add(SpriteRender("sprites/slime_green.png", vec2i(32, 32), SpriteLayer.Character));
            ent.add(HP(5));
            ent.add(TileBlock());
            ent.add(AISlimeGreen());
            ent.add(PrimaryWeaponSlot(Attack(2)));
            ent.add(AttackBait());
            ent.add(Name("green slime"));
            break;
        }
        case("stairs_up"):{
            ent.add(SpriteRender("sprites/stairs_up.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(Name("stairs"));
            ent.add(Stairs("up"));
            break;
        }
        case("stairs_down"):{
            ent.add(SpriteRender("sprites/stairs_down.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(Name("stairs"));
            ent.add(Stairs("down"));
            break;
        }
        case("press_plate"):{
            ent.add(SpriteRender("sprites/press_plate.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(PressurePlate());
            break;
        }
        case("arrow_trap"):{
            ent.add(SpriteRender("sprites/crossbow.png", vec2i(32, 32), SpriteLayer.Door));
            ent.add(ArrowTrap());
            break;
        }
        case("arrow"):{
            ent.add(TravellingProjectile());
            break;
        }
        case(""):{
        }
        default:
            writeln("Invalid entity string \"" ~ s ~"\"");
            ent.free();
            return ent.init;
    }
    return ent;
}

static Entity spawnNewPlayer(Universe verse){
    Entity ent = Entity(verse.allocEntity);
    ent.add(Name("Hero"));
    ent.add(SpriteRender("sprites/playerChar.png", vec2i(32, 32), SpriteLayer.Character));
    ent.add(Transform(vec2i(0, 0)));
    ent.add(MapPos(vec2i(0, 0)));
    ent.add(TileBlock());
    ent.add(HP(10));
    ent.add(PrimaryWeaponSlot(Attack(1)));
    ent.add(ShieldSlot());
    ent.add(DR());
    player = ent;
    return ent;
}

void registerComponents(ref UniverseAllocated ev)
{
    ev.universe.registerBuiltinComponents;
    registerSimpleComponents(ev.universe);
    registerEquipComponents(ev.universe);
    registerAIComponents(ev.universe);
    registerComplexComponents(ev.universe);
    registerTrapComponents(ev.universe);
}