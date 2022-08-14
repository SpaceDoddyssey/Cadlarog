module components.complex;

import dplug.math.vector;
import ecsd;
import ecsd.events;
import std.stdio;
import std.typecons;
import std.random;
import std.conv;
import vibe.data.serialization;
import vibe.data.bson;

import rendermodule;
import events;
import guiinfo;
import playermodule;
import components;

struct HP{
    int curHP, maxHP, damRed = 0;
    @ignore
    Entity ent;
    this(int h){
        curHP = maxHP = h;
    }
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        ent = Entity(owner);
        (ent.get!PubSub).subscribe(&receiveAttack);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&receiveAttack);
    }
    void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        if(curHP <= 0){
            Name* name = ent.get!Name;
            if(*name == "Hero"){
                addLogMessage("The Hero has fallen. All hope is lost!");
            } else {
                addLogMessage("The " ~ *name ~ " is destroyed");
            }
            (ent.get!PubSub).publish(DeathEvent());
            ent.free();
        }
        //Note: maybe should handle death better 
    }
    void receiveAttack(Entity e, ref AttackEvent atEv){
        writeln("Hello");
        int damageDone = atEv.a.damage - damRed;
        if(damageDone < 0) { damageDone = 0; }
        if(atEv.source == player){
            string s = "You deal " ~ to!string(damageDone) ~ " damage to the " ~ *(atEv.victim.get!Name);
            addLogMessage(s);
        } else if (atEv.victim == player){
            string s = "The " ~ *(atEv.source.get!Name) ~ " deals " ~ to!string(damageDone) ~ " damage to you!";
            addLogMessage(s);
        }
        int d = atEv.damage;
        takeDamage(d);
    }
}

struct Door{
    bool isOpen;
    string openSprite, closedSprite;
    @ignore
    Entity ent;
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        ent = Entity(owner);
        (ent.get!PubSub).subscribe(&doorOpen);
        (ent.get!PubSub).subscribe(&doorClose);
    }
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
    @ignore
    Entity ent;
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        ent = Entity(owner);
        (ent.get!PubSub).subscribe(&die);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&die);
    }
    void addContents(Entity e){
        if(e.has!SpriteRender){
            (e.get!SpriteRender()).enabled = false;
        }
        if(e.has!MapPos){
            e.remove!MapPos;
        }
        contents ~= e;
    }
    void die(Entity e, ref DeathEvent d){
        MapPos* thisPos = ent.get!MapPos;
        foreach(Entity cont ; contents){
            (cont.get!SpriteRender()).enabled = true;
            vec2i pos = thisPos.position;
            cont.add(MapPos(pos));
            publish(PlaceEntity(cont, pos));
            addLogMessage("The crate dropped a " ~ *(cont.get!Name()) ~ "!");
        }
    }
}

void registerComplexComponents(Universe verse)
{
    verse.registerComponent!SpriteRender;
    verse.registerComponent!HP;
    verse.registerComponent!Door;
    verse.registerComponent!Contents;
}