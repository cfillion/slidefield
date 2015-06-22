#include "window.hpp"

#include <algorithm>
#include <boost/format.hpp>

const int FRAME_RATE = 60;

void window::draw_event(GtkWidget *, cairo_t *cr, gpointer ptr)
{
  window *win = static_cast<window *>(ptr);
  win->draw(cr);
}

void window::key_event(GtkWidget *, GdkEventKey *e, gpointer ptr)
{
  window *win = static_cast<window *>(ptr);
  win->handle_key(e->keyval);
}

void window::state_event(GtkWidget *, GdkEventWindowState *e, gpointer ptr)
{
  window *win = static_cast<window *>(ptr);
  win->handle_state(e->new_window_state, e->changed_mask);
}

gboolean window::timer_tick(gpointer ptr)
{
  window *win = static_cast<window *>(ptr);
  win->update();
  return gtk_true();
}

window::window(const std::string &caption)
  : m_caption(caption)
{
  gtk_init(0, NULL);

  setup_window();
  setup_canvas();
}

void window::setup_window()
{
  m_win = gtk_window_new(GTK_WINDOW_TOPLEVEL);

  // TODO: derive the default size from the size of the layout object
  gtk_window_set_default_size(GTK_WINDOW(m_win), 640, 480);
  gtk_window_set_type_hint(GTK_WINDOW(m_win), GDK_WINDOW_TYPE_HINT_DIALOG);
  update_title();

  g_signal_connect(m_win, "key-press-event", G_CALLBACK(key_event), this);
  g_signal_connect(m_win, "window-state-event", G_CALLBACK(state_event), this);
  g_signal_connect(m_win, "destroy", G_CALLBACK(gtk_main_quit), NULL);

  g_timeout_add(1000 /  FRAME_RATE, timer_tick, this);
}

void window::setup_canvas()
{
  m_darea = gtk_drawing_area_new();
  gtk_container_add(GTK_CONTAINER(m_win), m_darea);

  g_signal_connect(G_OBJECT(m_darea), "draw", G_CALLBACK(draw_event), this);
}

void window::show()
{
  gtk_widget_show_all(m_win);
  gtk_main();
}

void window::update()
{
  if(true) // TODO: redraw only if necessary
    gtk_widget_queue_draw(m_darea);
}

void window::close()
{
  gtk_main_quit();
}

void window::handle_key(const int key)
{
  switch(key) {
  case GDK_KEY_q:
  case GDK_KEY_Escape:
    close();
    break;
  case GDK_KEY_f:
    toggle_fullscreen();
    break;
  }
}

void window::handle_state(GdkWindowState &new_state, GdkWindowState &changes)
{
  m_state = new_state;

  if(changes & GDK_WINDOW_STATE_FULLSCREEN)
    update_cursor();
}

bool window::is_fullscreen()
{
  return m_state & GDK_WINDOW_STATE_FULLSCREEN;
  return false;
}

void window::toggle_fullscreen()
{
  if(is_fullscreen())
    gtk_window_unfullscreen(GTK_WINDOW(m_win));
  else
    gtk_window_fullscreen(GTK_WINDOW(m_win));
}

void window::update_title()
{
  boost::format fmt = boost::format("%s (%d/%d) — %s")
    % "hello world" % 1 % 2 % m_caption;

  gtk_window_set_title(GTK_WINDOW(m_win), fmt.str().c_str());
}

void window::update_cursor()
{
  GdkWindow *win = gtk_widget_get_window(m_win);
  GdkCursor *cursor = gdk_cursor_new_for_display(gdk_display_get_default(),
    is_fullscreen() ? GDK_BLANK_CURSOR : GDK_ARROW);

  gdk_window_set_cursor(win, cursor);
}

void window::draw(cairo_t *cr)
{
  const int win_w = gtk_widget_get_allocated_width(m_darea);
  const int win_h = gtk_widget_get_allocated_height(m_darea);

  cairo_rectangle(cr, 0, 0, win_w, win_h);
  cairo_set_source_rgb(cr, 0, 0, 0);
  cairo_fill(cr);

  transform(cr, win_w, win_h);

  // TODO: draw frames here
  cairo_set_source_rgb(cr, 1,11, 0);
  cairo_rectangle(cr, 0, 0, 1080, 720);
  cairo_fill(cr);
}

void window::transform(cairo_t *cr, const double win_w, const double win_h)
{
  const double zoom = std::min(win_w / 1080, win_h / 720);
  const int real_w = 1080 * zoom;
  const int real_h = 720 * zoom;
  const int offset_x = (win_w - real_w) / 2;
  const int offset_y = (win_h - real_h) / 2;

  cairo_translate(cr, offset_x, offset_y);
  cairo_scale(cr, zoom, zoom);

  cairo_rectangle(cr, 0, 0, 1080, 720);
  cairo_clip(cr);
}
