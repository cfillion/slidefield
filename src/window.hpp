#ifndef WINDOW_HPP
#define WINDOW_HPP

#include <string>

struct SDL_KeyboardEvent;
struct SDL_Renderer;
struct SDL_Window;
struct SDL_WindowEvent;

class Window
{
public:
  Window(const std::string &caption);
  ~Window();

  void show();
  void redraw();
  void close();

private:
  void process_events();
  void keyboard_event(SDL_KeyboardEvent &);
  void window_event(SDL_WindowEvent &);

  bool is_fullscreen();
  void toggle_fullscreen();
  void update_title();

  std::string m_caption;
  SDL_Window *m_win;
  SDL_Renderer *m_ren;

  bool m_exit;
  bool m_set_cursor;
};

class WindowError
{
public:
  WindowError(const std::string &what, const std::string &why)
    : m_what(what), m_why(why)
  {}

  std::string what() const { return m_what + " failed: " + m_why; }

  std::string m_what;
  std::string m_why;
};

#endif
