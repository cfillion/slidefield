#include "window.hpp"

#include <boost/format.hpp>
#include <cairo/cairo.h>
#include <SDL2/SDL.h>

const int FRAME_RATE = 60;

static WindowError make_error(const std::string &what)
{
  throw WindowError(what, SDL_GetError());
}

static int event_filter(void *ptr, SDL_Event *e)
{
  // This prevent having a black window when the user is resizing the window.
  // The event filter is always called, even when SDL stops the event loop.
  if(e->window.event == SDL_WINDOWEVENT_RESIZED) {
    Window *win = static_cast<Window *>(ptr);
    win->redraw();
  }

  return 1;
}

Window::Window(const std::string &caption)
  : m_caption(caption), m_win(0), m_exit(false)
{
  if(SDL_Init(SDL_INIT_VIDEO) != 0)
    throw make_error("SDL_Init");
}

Window::~Window()
{
  if(m_ren)
    SDL_DestroyRenderer(m_ren);

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
    throw make_error("CreateWindow");

  m_ren = SDL_CreateRenderer(m_win, -1,
    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

  if(!m_ren)
    throw make_error("CreateRenderer");

  update_title();

  SDL_SetEventFilter(&event_filter, this);

  while(!m_exit) {
    process_events();
    redraw();
    SDL_Delay(1000 / FRAME_RATE);
  }
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

void Window::redraw()
{
  int out_w, out_h;

  SDL_GetRendererOutputSize(m_ren, &out_w, &out_h);

  SDL_Texture *tex = SDL_CreateTexture(m_ren,
    SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
    out_w, out_h);

  if(!tex)
    throw make_error("CreateTexture");

  void *pixels;
  int pitch;

  if(SDL_LockTexture(tex, NULL, &pixels, &pitch) != 0)
    throw make_error("LockTexture");

  cairo_surface_t *cr_surface = cairo_image_surface_create_for_data(
    (unsigned char *)pixels, CAIRO_FORMAT_RGB24,
    out_w, out_h, pitch);

  cairo_t *cr = cairo_create(cr_surface);

  cairo_translate(cr, 0, 0);
  cairo_scale(cr, 1, 1);

  cairo_set_source_rgb(cr, 1, 1, 0);
  cairo_rectangle(cr, 0, 0, 1080, 720);
  cairo_fill(cr);

  SDL_UnlockTexture(tex);

  cairo_destroy(cr);
  cairo_surface_destroy(cr_surface);

  SDL_RenderClear(m_ren);
  SDL_RenderCopy(m_ren, tex, NULL, NULL);
  SDL_RenderPresent(m_ren);

  SDL_DestroyTexture(tex);
}

void Window::update_title()
{
  boost::format fmt = boost::format("%s (%d/%d) — %s")
    % "hello world" % 1 % 2 % m_caption;

  SDL_SetWindowTitle(m_win, fmt.str().c_str());
}
