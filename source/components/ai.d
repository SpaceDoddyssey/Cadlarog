module components.ai;

import components;
import components.equipslots;
import levelmap;
import playermodule;
import events;

import std.stdio;
import ecsd;
import ecsd.events;
import ecsd.userdata;
import vibe.data.serialization;
import std.random;
import dplug.math.vector;

struct SlimeAI{
    Dir curDir;
    @ignore
    Entity ent;
    @ignore
    LevelMap lm;
    MapPos* mp;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        lm = ent.universe.getUserdata!LevelMap;
        mp = ent.get!MapPos;
        curDir = cast(Dir)uniform(2, 4);
        subscribe(&onTick);
    }
    void onTick(ref TurnTick t){
        int xDelta = 0, yDelta = 0;
        if(curDir == Dir.Left){ xDelta = -1; }
        if(curDir == Dir.Right){ xDelta = 1; }
        if(curDir == Dir.Up){ yDelta = -1; }
        if(curDir == Dir.Down){ yDelta = 1; }

        Tile target = lm.getTile(mp.x + xDelta, mp.y + yDelta);
        Entity[] blockingEnts = target.entsWith!(TileBlock)();
        if(blockingEnts.length == 0){
            if(target.type == TileType.Floor){
            vec2i source = vec2i(mp.x, mp.y);
            vec2i dest = vec2i(mp.x + xDelta, mp.y + yDelta);
            lm.moveEntity(ent, source, dest);
            } else {
            turnAround();
            }
        } else if(blockingEnts[0] != player){
            turnAround();
        } else {
            player.get!PubSub.publish(AttackEvent(ent, player, (ent.get!PrimaryWeaponSlot).attack));
        }
    }
    void turnAround(){
        switch(curDir){
            case(Dir.Up): curDir = Dir.Down; break;
            case(Dir.Down): curDir = Dir.Up; break;
            case(Dir.Left): curDir = Dir.Right; break;
            case(Dir.Right): curDir = Dir.Left; break;
            default: writeln("How did this happen?  Slime AI turnaround");
        }
    }
}

void registerAIComponents(Universe verse){
    verse.registerComponent!SlimeAI;
}