module components.traps;

import components;
import dplug.math.vector;
import ecsd;
import ecsd.events;
import entitycreation;
import events;
import game;
import guimodule;
import vibe.data.bson;

struct PressurePlate{
    Entity trapToTrigger;
    Entity ent;
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        ent.subscribe(&trigger);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        if(!verse.serializing){
            ent.subscribe(&trigger);
        }
    }
    void trigger(Entity e, ref WalkedOnto w){
        trapToTrigger.publish(Trigger());
    }
}

struct ArrowTrap{
    Entity ent;
    vec2i direction;
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        ent.subscribe(&trigger);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        if(!verse.serializing){
            ent.subscribe(&trigger);
        }
    }
    void trigger(Entity e, ref Trigger t){
        rangedAttack(makeEntity(uni, "arrow", null), ent.get!MapPos.position, direction);
    }
}

void registerTrapComponents(Universe verse){
    verse.registerComponent!PressurePlate;
    verse.registerComponent!ArrowTrap; 
}