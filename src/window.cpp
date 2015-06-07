#include "window.hpp"

#include <boost/format.hpp>
#include <SDL2/SDL.h>

const int FRAME_RATE = 60;

static Uint32 timer_tick(Uint32, void *pointer)
{
  Window *win = static_cast<Window *>(pointer);
  win->redraw();
  return 1000 / FRAME_RATE;
}

Window::Window(const std::string &caption)
  : m_caption(caption), m_win(0), m_exit(false)
{
  if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
    throw SDL_GetError();
}

Window::~Window()
{
  if(m_win)
    SDL_DestroyWindow(m_win);

  SDL_Quit();
}

void Window::show()
{
  m_win = SDL_CreateWindow("",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480,
    SDL_WINDOW_RESIZABLE);

  if(!m_win)
    throw SDL_GetError();

  update_title();
  SDL_TimerID timer = SDL_AddTimer(0, &timer_tick, this);

  while(!m_exit) {
    process_events();
    SDL_Delay(42);
  }

  SDL_RemoveTimer(timer);
}

void Window::close()
{
  m_exit = true;
}

void Window::process_events()
{
  SDL_Event e;

  while(SDL_PollEvent(&e)) {
    switch(e.type) {
    case SDL_KEYDOWN:
      keyboard_event(e.key);
      break;
    case SDL_WINDOWEVENT:
      window_event(e.window);
      break;
    case SDL_QUIT:
      close();
      break;
    }
  }
}

void Window::keyboard_event(SDL_KeyboardEvent &e)
{
  switch(e.keysym.sym) {
  case SDLK_q:
  case SDLK_ESCAPE:
    close();
    break;
  case SDLK_f:
    toggle_fullscreen();
    break;
  }
}

void Window::window_event(SDL_WindowEvent &e)
{
  switch(e.event) {
  case SDL_WINDOWEVENT_RESIZED:
    SDL_ShowCursor(!is_fullscreen());
    break;
  }
}

bool Window::is_fullscreen()
{
  return SDL_GetWindowFlags(m_win) & SDL_WINDOW_FULLSCREEN_DESKTOP;
}

void Window::toggle_fullscreen()
{
  if(is_fullscreen())
    SDL_SetWindowFullscreen(m_win, 0);
  else
    SDL_SetWindowFullscreen(m_win, SDL_WINDOW_FULLSCREEN_DESKTOP);
}

#include <iostream>
void Window::redraw()
{
  std::cout << SDL_GetTicks() << std::endl;
}

void Window::update_title()
{
  boost::format fmt = boost::format("%s (%d/%d) — %s")
    % "hello world" % 1 % 2 % m_caption;

  SDL_SetWindowTitle(m_win, fmt.str().c_str());
}
