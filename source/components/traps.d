module components.traps;

import ecsd;
import ecsd.events;
import events;
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
        addLogMessage("ARROW'D!!!!");
    }
}

void registerTrapComponents(Universe verse){
    verse.registerComponent!PressurePlate;
    verse.registerComponent!ArrowTrap; 
}