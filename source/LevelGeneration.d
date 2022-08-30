module levelgen;

import ecsd;
import components;
import components.complex; 

import events;
import levelmap;
import entitycreation;
import std.stdio;
import dplug.math.vector;
import randommodule;
import std.random;
import std.algorithm.searching;
import game;
import playermodule;
import rendermodule;

static void initialize(LevelMap lev){
    writeln("Populating ", lev.maxWidth, " * ", lev.maxHeight, " tiles");
    for(int x = 0; x < lev.maxWidth; x++){
        for(int y = 0; y < lev.maxHeight; y++){
            Tile T;
            T.setPos(cast(int)(x*lev.tileSize), cast(int)(y*lev.tileSize));
            T.mpos.x = x; T.mpos.y = y;
            T.type = TileType.Wall;
            lev.getTile(x,y) = T;
        }
    }
}

Rect[] partitionPhase(LevelMap lev, int numPartitions){
    writeln("Partitioning ", numPartitions, " times");
    Rect[] partitions;
    //The first "partition" is the entire map
    vec2i alpha = vec2i(0, 0);
    vec2i omega = vec2i(lev.maxWidth-1, lev.maxHeight-1);
    Rect wholeMap = Rect(alpha, omega);
    partitions ~= (wholeMap);
//writeln("Partitioning ", numPartitions, " times");
    for(int i = 0; i < numPartitions; i++){
        Rect[] newPartitions;
        if(i % 2 == 0){ //Vertical
            foreach(ref Rect space; partitions){
                newPartitions ~= (space.partitionVertical());
                for(int y = space.mins.y; y <= space.maxs.y; y++){
                    lev.getTile(space.maxs.x+1,y).type = TileType.Floor;
                }
            }
        } else { //Horizontal
            foreach(ref Rect space; partitions){
                newPartitions ~= (space.partitionHorizontal());
                for(int x = space.mins.x; x <= space.maxs.x; x++){
                    lev.getTile(x,space.maxs.y+1).type = TileType.Floor;
                }
            }
        }
        partitions ~= (newPartitions);
    } 
    return partitions;
}


//Takes the partitions and generates rooms in numRooms spaces. 
//If numRooms is greater than the number of partitions, puts a room in every partition
void roomGenPhase(LevelMap lev, Rect[] partitions, int numRooms){
    int[] alreadyUsed;

    //writeln("roomGenPhase");
    for(int p=0; p<partitions.length; p++) {
        Rect r = partitions[p];
        //writeln("   p=", p,
        //    ", min=(", r.mins.x, ",", r.mins.y,
        //    "), max=(", r.maxs.x, ",", r.maxs.y, ")" );
    }

    for(int i = 0; i < numRooms && i < partitions.length; i++){
        int nextIndex = cast(int)uniform(0, partitions.length, levelGenRand);
        if(canFind(alreadyUsed, nextIndex)){
            i--;
            continue;
        }
        alreadyUsed ~= nextIndex;
        Rect space = partitions[nextIndex];
        int minX, minY;
        //writeln("-----\n mins.x:",space.mins.x,"  mins.y:",space.mins.y,        "\n max.x:",space.maxs.x," max.y:",space.maxs.y,        "\n lev.minRoomWidth:",lev.minRoomWidth," lev.minRoomHeight:",lev.minRoomHeight,);
        if(space.mins.x >= space.maxs.x - lev.minRoomWidth){
            minX = cast(int)space.mins.x;
        } else {
            minX = cast(int)uniform(space.mins.x, space.maxs.x - lev.minRoomWidth, levelGenRand);
        }           
        if(space.mins.y >= space.maxs.y - lev.minRoomHeight){
            minY = cast(int)space.mins.y;
        } else {
            minY = cast(int)uniform(space.mins.y, space.maxs.y - lev.minRoomHeight, levelGenRand);
        }
        vec2i botLeft = vec2i(minX, minY);

        int topX, topY;
        if(minX + lev.minRoomWidth >= space.maxs.x){
            topX = space.maxs.x;
        } else {
            topX = cast(int)uniform(minX + lev.minRoomWidth, space.maxs.x, levelGenRand);
        }
        if(minY + lev.minRoomHeight >= space.maxs.y){
            topY = space.maxs.y;
        } else {
            topY = cast(int)uniform(minY + lev.minRoomHeight, space.maxs.y, levelGenRand);
        }
        vec2i topRight = vec2i(topX, topY);

        Rect newRect = Rect(botLeft, topRight);
        lev.rooms ~= Room(newRect);
    }
write("Placing rooms in partitions ");
foreach(int i ; alreadyUsed){ write(i, " "); }
writeln("");
    foreach(Room r; lev.rooms){
        for(int x = r.rect.mins.x; x <= r.rect.maxs.x; x++){
            for(int y = r.rect.mins.y; y <= r.rect.maxs.y; y++){
                //Debug.Log("(" + x + "," + y + ")");
                if(x == r.rect.mins.x || y == r.rect.mins.y || x == r.rect.maxs.x || y == r.rect.maxs.y){
                    lev.getTile(x, y).type = TileType.RoomBorder;
                } else {
                    lev.getTile(x, y).type = TileType.Floor;
                }
            }
        }
    }
}
bool plumbLineToPath(LevelMap lev, Room room){
    int side = uniform(0, 4, levelGenRand);
    int xPos, yPos; //Position of the door to be placed
    int xWalkDelta, yWalkDelta; //How much to offset each of these values (-1, 0, or 1) each step depending on what dir we're walking
    if(side <= 1){ //up-down
        xPos = uniform(room.rect.mins.x+1, room.rect.maxs.x, levelGenRand);
        xWalkDelta = 0;
        if(side == 0){ //up
            yPos = room.rect.maxs.y;
            yWalkDelta = 1;
        } else {
            yPos = room.rect.mins.y;
            yWalkDelta = -1;
        }
    } else { //left-right
        yPos = uniform(room.rect.mins.y+1, room.rect.maxs.y, levelGenRand);
        yWalkDelta = 0;
        if(side == 3){ //left
            xPos = room.rect.mins.x;
            xWalkDelta = -1;
        } else {
            xPos = room.rect.maxs.x;
            xWalkDelta = 1;
        }
    }

    int nextX = xPos;
    int nextY = yPos;
    int attempts = 0;
    while(true){
        if(attempts++ >= 100){
            writeln("Aborted! ", __FILE__, " line ", __LINE__);
            return false;
        }
        nextX += xWalkDelta;
        nextY += yWalkDelta;
        if(!(nextX < lev.maxWidth && nextX > 0 && nextY < lev.maxHeight && nextY > 0)){
            return false;
        } else if (lev.getTile(nextX, nextY).type == TileType.Floor) {
            break;
        }
    }

    //If we're here, we've hit a path. Walk back and change tiles to floor.
    while(nextX != xPos || nextY != yPos){
        nextX -= xWalkDelta;
        nextY -= yWalkDelta;
        lev.getTile(nextX, nextY).type = TileType.Floor;
    }

    //now place a door there
    Entity door = makeEntity(lev.verse, "door", null);
    publish(PlaceEntity(door, vec2i(xPos, yPos)));
    lev.getTile(xPos, yPos).add(door);

    return true;
}

static void cullDeadEnds(LevelMap lev){
    writeln("Culling dead ends");
    for(int x = 1; x < lev.maxWidth; x++){ //First check top and bottom
        if(lev.getTile(x, 0).type == TileType.Floor){
            int y = 0;
            while(lev.getTile(x+1, y).type != TileType.Floor && lev.getTile(x-1, y).type != TileType.Floor){
                lev.getTile(x, y).type = TileType.Wall;
                y++;
            }
        } 
        if (lev.getTile(x, lev.maxHeight-1).type == TileType.Floor){
            int y = lev.maxHeight - 1;
            while(lev.getTile(x+1, y).type != TileType.Floor && lev.getTile(x-1, y).type != TileType.Floor){
                lev.getTile(x, y).type = TileType.Wall;
                y--;
            }
        }
    }
    for(int y = 1; y < lev.maxHeight; y++){ //Now check left and right
        if(lev.getTile(0, y).type == TileType.Floor){
            int x = 0;
            while(lev.getTile(x, y+1).type != TileType.Floor && lev.getTile(x, y-1).type != TileType.Floor){
                lev.getTile(x, y).type = TileType.Wall;
                x++;
            }
        }
        if (lev.getTile(lev.maxWidth-1, y).type == TileType.Floor){
            int x = lev.maxWidth - 1;
            while(lev.getTile(x, y+1).type != TileType.Floor && lev.getTile(x, y-1).type != TileType.Floor){
                lev.getTile(x, y).type = TileType.Wall;
                x--;
            }
        }
    }
}

static void populate(){
    writeln("Populating entities");
    //Populate 'primary' room
    Room spawnRoom = lm.getRandomRoom();
    lm.placeEntInRoom("crate", "sword", spawnRoom);
    lm.placeEntInRoom("crate", "shield", spawnRoom);
    lm.placeEntInRoom("slime_purple", null, spawnRoom);
    lm.placeEntInRoom("slime_green", null, spawnRoom);

    lm.placeEntInRoom("crate", "sword", lm.getRandomRoom());
    //Place down stairs
    Room r = lm.getRandomRoom();
    vec2i stairsLoc = r.randPointIn();
    Entity downStairs = makeEntity(uni, "stairs_down", null);
    publish(PlaceEntity(downStairs, stairsLoc));
    lm.stairsDownLoc = stairsLoc;
    //Place up stairs
    if(lm.levelNum != 0){
        r = lm.getRandomRoom();
        stairsLoc = r.randPointIn();
        Entity upStairs = makeEntity(uni, "stairs_up", null);
        publish(PlaceEntity(upStairs, stairsLoc));
        lm.stairsUpLoc = stairsLoc;
    } else {
        lm.placeEntInRoom(player, spawnRoom);
        MapPos* mp = player.get!MapPos();
        cameraXOffset = mp.x - 15;
        cameraYOffset = mp.y - 15;
    }
}

void texturePhase(LevelMap lev){
    import rendermodule: SpriteRender, SpriteLayer;
    foreach(t; lev.tiles){
        string target;
        switch(t.type){
            case(TileType.Floor):
                target = "sprites/Floor.png"; break;
            case(TileType.RoomBorder):
                target = "sprites/RoomBorder.png"; break;
            default:
                target = "sprites/Empty.png"; break;
        }
        t.tileEnt = makeEntity(lev.verse, "Tile", null);
        publish(PlaceEntity(t.tileEnt, t.pos.position));
        t.tileEnt.add(SpriteRender(target, vec2i(32, 32), SpriteLayer.Floor));
    }
}