module input;

import ecsd;
import events;
import levelmap;
import playermodule;
import bindbc.sdl;
import dplug.math.vector;

import std.stdio;
mixin registerSubscribers;

private:

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

@EventSubscriber
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

@EventSubscriber
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
    
	//Player actions
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

		//Player actions
		if(isKeyPressed(SDLK_p, true))
			publish(PickUp());
	}
}

/*
// binds that do logic every frame the key is down
if(isKeyPressed(SDLK_w))
  accel.y -= 1;

// binds that do logic only on the first frames where given key is pressed
if(isKeyPressed(SDLK_space, true))
  attack();
*/