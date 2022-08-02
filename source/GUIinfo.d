module guiinfo;

import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.sdl.ttf;
import std.stdio;

TTF_Font* curFont;

int fontSize = 16;
string fontPath = "fonts/PressStart2P-Regular.ttf";

TextBox[] messages;

SDL_Color white = { 0xFF, 0xFF, 0xFF, 0 };
SDL_Color black = { 0x00, 0x00, 0x00, 0 };

void addLogMessage(string mess){
    messages ~= TextBox(mess);
}

struct TextBox{
    string message;
    bool initialized = false;
    int textWidth, textHeight;
    //SDL_Surface * surface;
    SDL_Texture * texture;
    this(string s){
        message = s;
    }
}