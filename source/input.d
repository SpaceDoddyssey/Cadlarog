module input;

import ecsd;
import events;
import game;
import levelmap;
import playermodule;
import rendermodule;

import bindbc.sdl;
import dplug.math.vector;
import std.stdio;

bool[SDL_NUM_SCANCODES] keyboardState;
bool[6] buttonState; // no _NUM_ enum :(
vec2i mousePos;

bool isKeyPressed(SDL_Keycode key, bool release = false)
{
	const scancode = SDL_GetScancodeFromKey(key);
	scope(exit) if(release) keyboardState[scancode] = false;
	return keyboardState[scancode];
}

bool isButtonPressed(ubyte button, bool release = false)
{
	assert(button > 0 && button < 6);
	scope(exit) if(release) buttonState[button] = false;
	return buttonState[button];
}

vec2i getMousePos()
{
	return mousePos;
}

void processEvent(ref SDLEvent ev)
{
	switch(ev.type)
	{
		case SDL_KEYDOWN:
		case SDL_KEYUP:
//    writeln(ev.key.keysym.scancode);
			keyboardState[ev.key.keysym.scancode] = ev.type == SDL_KEYDOWN;
			break;
		case SDL_MOUSEBUTTONDOWN:
		case SDL_MOUSEBUTTONUP:
			buttonState[ev.button.button] = ev.type == SDL_MOUSEBUTTONDOWN;
			break;
		case SDL_MOUSEMOTION:
			mousePos = vec2i(ev.motion.x, ev.motion.y);
			break;
		default:
	}
}

void controlHandling(ref LoopStruct l){
	//Escape key exit handled in app.d

	//Camera movement
    if(isKeyPressed(SDLK_DOWN))
        publish(CameraMove(Dir.Down)); 
    if(isKeyPressed(SDLK_UP))
        publish(CameraMove(Dir.Up)); 
    if(isKeyPressed(SDLK_LEFT))
        publish(CameraMove(Dir.Left)); 
    if(isKeyPressed(SDLK_RIGHT))
        publish(CameraMove(Dir.Right));
	if(isKeyPressed(SDLK_MINUS, true))
		zoomFactor++;
	if(isKeyPressed(SDLK_EQUALS, true))
		if(zoomFactor > 1){
			zoomFactor--;
		}
    
	//Disabled if player is dead
	if(player.valid){
		//Player movement
		if(isKeyPressed(SDLK_s, true))
			publish(PlayerMove(Dir.Down)); 
		if(isKeyPressed(SDLK_w, true))
			publish(PlayerMove(Dir.Up)); 
		if(isKeyPressed(SDLK_a, true))
			publish(PlayerMove(Dir.Left)); 
		if(isKeyPressed(SDLK_d, true))
			publish(PlayerMove(Dir.Right));

		if(isKeyPressed(SDLK_SPACE, true))
			publish(PlayerMove(Dir.None));

		//Player actions
		if(isKeyPressed(SDLK_p, true))
			publish(PickUp());
		//if(isKeyPressed(SDLK_k, true))
		if(isKeyPressed(SDLK_l, true))
			changeLevel(gameData.curLevel + 1);	
		if(isKeyPressed(SDLK_o, true))
			if(gameData.curLevel != 0){
				changeLevel(gameData.curLevel - 1);
			}	
	}
	if(isKeyPressed(SDLK_F5, true))
		saveGame();
	if(isKeyPressed(SDLK_F8, true))
		loadGame();
}