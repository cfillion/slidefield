#ifndef WINDOW_HPP
#define WINDOW_HPP

#include <cairo/cairo.h>
#include <gtk/gtk.h>
#include <string>

class window
{
public:
  window(const std::string &caption);

  void show();
  void update();
  void close();

private:
  void setup_window();
  void setup_canvas();

  static void draw_event(GtkWidget *, cairo_t *, gpointer);
  void draw(cairo_t *cr);
  void transform(cairo_t *cr, const double w, const double h);

  static void key_event(GtkWidget *, GdkEventKey *, gpointer);
  void handle_key(const int key);

  static void state_event(GtkWidget *, GdkEventWindowState *, gpointer);
  void handle_state(GdkWindowState &new_state, GdkWindowState &changes);

  static gboolean timer_tick(gpointer);

  bool is_fullscreen();
  void toggle_fullscreen();

  void update_title();
  void update_cursor();

  std::string m_caption;
  GdkWindowState m_state;

  GtkWidget *m_win;
  GtkWidget *m_darea;
};

#endif
