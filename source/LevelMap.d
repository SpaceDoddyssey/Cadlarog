module levelmap;

import events;
import app;
import ecsd;
import renderer;
import entitycreation;
import perf;
import components;
import set;

import dplug.math.vector;
import std.stdio;
import bindbc.sdl;
import bindbc.sdl.image;
import std.random;
import std.algorithm.searching;

LevelMap levelinit(int x, int y){ 
    LevelMap lm = new LevelMap(x, y);
    spriteDrawables = new typeof(spriteDrawables)(lm.verse);

    writeln("level init");

    return lm;
}

class LevelMap{
    public:
        int levelNum;
        Universe verse;
        static float tileSize = 1.0f;
        Random rand;
        static int seed = 300;
        int maxWidth, maxHeight;
        int minRoomWidth = 5, minRoomHeight = 5;
        int maxRoomWidth = 8, maxRoomHeight = 8;
        //Chunk[] chunks;
        Tile[] tiles;
        Room[] rooms;
        float tileOffsetX = 0, tileOffsetY = 0;
        this(int _x, int _y){
            verse = allocUniverse();
            registration(verse);
            
            rand = Random(seed);

            maxWidth = _x;
            maxHeight = _y;
            tiles = new Tile[_x * _y];
            initialize();
            Rect[] partitions = partitionPhase(4);
            roomGenPhase(partitions, 6);
            foreach(Room r ; rooms){
                while(!plumbLineToPath(r)){}
                while(!plumbLineToPath(r)){}
            }
            cullDeadEnds();
            Room r = placePlayer();
            placeEntInRandomRoom("Crate");
            placeEntInRoom("Crate", r);
            texturePhase();
        }
    ref Tile getTile(int x, int y) { return tiles[y * maxWidth + x]; }
    ref Tile getTile(vec2i pos) { return getTile(pos.v.tupleof); }
    private void initialize(){
        //tileOffsetX = tileSize * (maxWidth/2);
        //tileOffsetY = tileSize * (maxHeight/2);
        for(int x = 0; x < maxWidth; x++){
            for(int y = 0; y < maxHeight; y++){
                Tile T;
                T.setPos(cast(int)(-tileOffsetX+(x*tileSize)), cast(int)(-tileOffsetY+(y*tileSize)));
                T.mpos.x = x; T.mpos.y = y;
                T.type = TileType.Wall;
                getTile(x,y) = T;
            }
        }
    }
    private Rect[] partitionPhase(int numPartitions){
        Rect[] partitions;
        //The first "partition" is the entire map
        vec2i alpha = vec2i(0, 0);
        vec2i omega = vec2i(maxWidth-1, maxHeight-1);
        Rect wholeMap = new Rect(alpha, omega);
        partitions ~= (wholeMap);
        for(int i = 0; i < numPartitions; i++){
            Rect[] newPartitions;
            if(i % 2 == 0){
                foreach(Rect space; partitions){
                    newPartitions ~= (space.partitionVertical(rand));
                    for(int y = space.mins.y; y <= space.maxs.y; y++){
                        getTile(space.maxs.x+1,y).type = TileType.Floor;
                    }
                }
            } else {
                foreach(Rect space; partitions){
                    newPartitions ~= (space.partitionHorizontal(rand));
                    for(int x = space.mins.x; x <= space.maxs.x; x++){
                        getTile(x,space.maxs.y+1).type = TileType.Floor;
                    }
                }
            }
            partitions ~= (newPartitions);
        } 
        return partitions;
    }
    //Takes the partitions and generates rooms in numRooms spaces. 
    //If numRooms is greater than the number of partitions, puts a room in every partition
    private void roomGenPhase(Rect[] partitions, int numRooms){
        int[] alreadyUsed;
        for(int i = 0; i < numRooms && i < partitions.length; i++){
            int nextIndex = cast(int)uniform(0, partitions.length, rand);
            if(canFind(alreadyUsed, nextIndex)){
                i--;
                continue;
            }
            alreadyUsed ~= nextIndex;
            Rect space = partitions[nextIndex];
            int minX, minY;
//writeln("-----\n mins.x:",space.mins.x,"  mins.y:",space.mins.y,        "\n max.x:",space.maxs.x," max.y:",space.maxs.y,        "\n minRoomWidth:",minRoomWidth," minRoomHeight:",minRoomHeight,);
            if(space.mins.x == space.maxs.x - minRoomWidth){
                minX = cast(int)space.mins.x;
            } else {
                minX = cast(int)uniform(space.mins.x, space.maxs.x - minRoomWidth, rand);
            }           
            if(space.mins.y == space.maxs.y - minRoomHeight){
                minY = cast(int)space.mins.x;
            } else {
                minY = cast(int)uniform(space.mins.y, space.maxs.y - minRoomHeight, rand);
            }
            vec2i botLeft = vec2i(minX, minY);

            int topX, topY;
            if(minX + minRoomWidth == space.maxs.x){
                topX = minX + minRoomWidth;
            } else {
                topX = cast(int)uniform(minX + minRoomWidth, space.maxs.x, rand);
            }
            if(minY + minRoomHeight == space.maxs.y){
                topY = minY + minRoomHeight;
            } else {
                topY = cast(int)uniform(minY + minRoomHeight, space.maxs.y, rand);
            }
            vec2i topRight = vec2i(topX, topY);

            Rect newRect = new Rect(botLeft, topRight);
            rooms ~= (new Room(newRect));
        }
        foreach(Room r; rooms){
            for(int x = r.rect.mins.x; x <= r.rect.maxs.x; x++){
                for(int y = r.rect.mins.y; y <= r.rect.maxs.y; y++){
                    //Debug.Log("(" + x + "," + y + ")");
                    if(x == r.rect.mins.x || y == r.rect.mins.y || x == r.rect.maxs.x || y == r.rect.maxs.y){
                        getTile(x, y).type = TileType.RoomBorder;
                    } else {
                        getTile(x, y).type = TileType.Floor;
                    }
                }
            }
        }
    }
    private bool plumbLineToPath(Room room){
//auto perf = Perf(null);
        int side = uniform(0, 4, rand);
        int xPos, yPos; //Position of the door to be placed
        int xWalkDelta, yWalkDelta; //How much to offset each of these values (-1, 0, or 1) each step depending on what dir we're walking
        if(side <= 1){ //up-down
            xPos = uniform(room.rect.mins.x+1, room.rect.maxs.x, rand);
            xWalkDelta = 0;
            if(side == 0){ //up
                yPos = room.rect.maxs.y;
                yWalkDelta = 1;
            } else {
                yPos = room.rect.mins.y;
                yWalkDelta = -1;
            }
        } else { //left-right
            yPos = uniform(room.rect.mins.y+1, room.rect.maxs.y, rand);
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
                writeln("Aborted! PL1");
                return false;
            }
            nextX += xWalkDelta;
            nextY += yWalkDelta;
            if(!(nextX < maxWidth && nextX > 0 && nextY < maxHeight && nextY > 0)){
                return false;
            } else if (getTile(nextX, nextY).type == TileType.Floor) {
                break;
            }
        }

        //If we're here, we've hit a path. Walk back and change tiles to floor.
        while(nextX != xPos || nextY != yPos){
            nextX -= xWalkDelta;
            nextY -= yWalkDelta;
            getTile(nextX, nextY).type = TileType.Floor;
        }

        //now place a door there
        Entity door = makeEntity(verse, "Door", xPos, yPos);
        getTile(xPos, yPos).add(door);

        return true;
    }
    private void cullDeadEnds(){
        for(int x = 1; x < maxWidth; x++){ //First check top and bottom
            if(getTile(x, 0).type == TileType.Floor){
                int y = 0;
                while(getTile(x+1, y).type != TileType.Floor && getTile(x-1, y).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    y++;
                }
            } 
            if (getTile(x, maxHeight-1).type == TileType.Floor){
                int y = maxHeight - 1;
                while(getTile(x+1, y).type != TileType.Floor && getTile(x-1, y).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    y--;
                }
            }
        }
        for(int y = 1; y < maxHeight; y++){ //Now check left and right
            if(getTile(0, y).type == TileType.Floor){
                int x = 0;
                while(getTile(x, y+1).type != TileType.Floor && getTile(x, y-1).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    x++;
                }
            }
            if (getTile(maxWidth-1, y).type == TileType.Floor){
                int x = maxWidth - 1;
                while(getTile(x, y+1).type != TileType.Floor && getTile(x, y-1).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    x--;
                }
            }
        }
    }
    private Room placePlayer(){
        int whichRoom = cast(int)uniform(0, rooms.length, rand);
        Room r = rooms[whichRoom];
        int playerX = cast(int)uniform(r.rect.mins.x+1, r.rect.maxs.x, rand);
        int playerY = cast(int)uniform(r.rect.mins.y+1, r.rect.maxs.y, rand);
        Entity pEnt = makePlayer(verse, playerX, playerY);
        writeln("Spawning player at ", playerX, " ", playerY );
        getTile(playerX, playerY).add(pEnt);
        return r;
        //Expand -------------------------------
    }
    private void placeEntInRandomRoom(string s){
        int whichRoom = cast(int)uniform(0, rooms.length, rand);
        Room r = rooms[whichRoom];
        int entX = cast(int)uniform(r.rect.mins.x+1, r.rect.maxs.x, rand);
        int entY = cast(int)uniform(r.rect.mins.y+1, r.rect.maxs.y, rand);
        Entity pEnt = makeEntity(verse, s, entX, entY);
        writeln("Spawning entity at ", entX, " ", entY );
        getTile(entX, entY).add(pEnt);
        //Expand -------------------------------
        //Make sure this doesn't place an object on a tile that's already full
    }
    private void placeEntInRoom(string s, Room r){
        int entX = cast(int)uniform(r.rect.mins.x+1, r.rect.maxs.x, rand);
        int entY = cast(int)uniform(r.rect.mins.y+1, r.rect.maxs.y, rand);
        Entity pEnt = makeEntity(verse, s, entX, entY);
        writeln("Spawning entity at ", entX, " ", entY );
        getTile(entX, entY).add(pEnt);
    }
    private void texturePhase(){
//auto perf = Perf(null);
        foreach(t; tiles){
            string target;
            switch(t.type){
                case(TileType.Floor):
                    target = "sprites/Floor.png"; break;
                case(TileType.RoomBorder):
                    target = "sprites/RoomBorder.png"; break;
                default:
                    target = "sprites/Empty.png"; break;
            }
            t.tileEnt = makeEntity(verse, "Tile", t.pos.position.x, t.pos.position.y);
            t.tileEnt.add(SpriteRender(target, vec2i(32, 32), SpriteLayer.Floor));
        }
    }
    void lookForEnts(){
        foreach(Tile t ; tiles){
            if(t.ents.length() != 0){
                writeln("Ent(s) found at ", t.mpos.x, " ", t.mpos.y);
            }
        }
        writeln("done looking");
    }
}

public struct Tile{
    Transform pos;
    MapPos mpos;
    TileType type;
    SDL_Texture* tex;
    Entity tileEnt = void;
    void setPos(int x, int y){
        pos.position.x = x;
        pos.position.y = y;
    }
    Set!Entity ents;
    Entity[] entsWith(Component)(){
        Entity[] result;
        foreach(Entity ent ; ents){
            if(ent.has!Component){
                result ~= ent;
            }
        }
        return result;
    }
    void add(Entity ent){ ents.add(ent); }
    void remove(Entity ent){ ents.remove(ent); }
}

enum TileType{
    Wall,
    Floor,
    RoomBorder
}

public class Rect
{
    public vec2i mins, maxs;
    public this(vec2i botLeft, vec2i topRight){
        mins = botLeft;
        maxs = topRight;
    }
    public int width(){
        return (maxs.x - mins.x);
    }
    public int height(){
        return (maxs.y - mins.y);
    }
    //Cuts the rectangle in half with a one-block-thick vertical slice, making this Rect the left-hand rectangle and returning the right-hand rectangle
    public Rect partitionVertical(Random rand){    
        int divisionPoint = uniform(mins.x + width()/3, maxs.x - width()/3, rand);
        
        vec2i firstTop = vec2i(divisionPoint - 1, maxs.y);

        vec2i secondOrigin = vec2i(divisionPoint + 1, mins.y);
        vec2i secondTop = maxs;
        Rect right = new Rect(secondOrigin, secondTop);

        maxs = firstTop;
        return right;
    }
    //Cuts the rectangle in half with a one-block-thick horizontal slice, making this Rect the bottom rectangle and returning the top rectangle
    public Rect partitionHorizontal(Random rand){    
        int divisionPoint = uniform(mins.y + height()/3, maxs.y - height()/3, rand);

        vec2i firstTop = vec2i(maxs.x, divisionPoint - 1);

        vec2i secondOrigin = vec2i(mins.x, divisionPoint + 1);
        vec2i secondTop = maxs;
        Rect top = new Rect(secondOrigin, secondTop);

        maxs = firstTop;
        return top;
    }
}

public class Room 
{
    public Rect rect;
    public this(Rect _rect){
        rect = _rect;
    }
    //Add function to get random tile in room
}