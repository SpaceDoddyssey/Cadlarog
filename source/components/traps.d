module components.traps;

import ecsd;
import ecsd.events;
import events;
import guimodule;

struct PressurePlate{
    Entity trapToTrigger;
    void onComponentAdded(Universe verse, EntityID id){
        subscribe(&trigger);
    }
    void trigger(ref WalkedOnto w){
        trapToTrigger.publish(w);
    }
}

struct ArrowTrap{
    void onComponentAdded(Universe verse, EntityID id){
        subscribe(&trigger);
    }
    void trigger(ref WalkedOnto w){
        addLogMessage("ARROW'D!!!!");
    }
}

void registerTrapComponents(Universe verse){
    
}