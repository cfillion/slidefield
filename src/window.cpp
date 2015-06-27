#include "window.hpp"

#include <algorithm>
#include <QKeyEvent>
#include <QPainter>
#include <QTimer>

const int FRAME_RATE = 60;

window::window(const std::string &caption)
  : QWidget(nullptr),
  m_caption(QString::fromStdString(caption))
{
#ifdef Q_OS_LINUX
  setWindowFlags(Qt::Dialog | Qt::CustomizeWindowHint |
    Qt::WindowCloseButtonHint | Qt::WindowMinMaxButtonsHint);
#endif

  setAttribute(Qt::WA_OpaquePaintEvent, true);
  update_title();

  m_timer = new QTimer(this);
  m_timer->setInterval(1000 / FRAME_RATE);
  m_timer->start();

  connect(m_timer, &QTimer::timeout, this, &window::update);
}

QSize window::sizeHint() const
{
  return QSize(640, 480);
}

void window::update()
{
  if(true) // TODO: redraw only if necessary
    QWidget::update();
}

void window::keyPressEvent(QKeyEvent *e)
{
  switch(e->key()) {
  case Qt::Key_Q:
  case Qt::Key_Escape:
    close();
    break;
  case Qt::Key_F:
    setWindowState(windowState() ^ Qt::WindowFullScreen);
    break;
  }
}

void window::paintEvent(QPaintEvent *)
{
  QPainter painter(this);

  // reset every pixels
  painter.fillRect(rect(), Qt::black);

  transform(painter, width(), height());

  // TODO: draw frames here
  painter.fillRect(QRect(0, 0, 1080, 720), Qt::yellow);

  painter.end();
}

void window::changeEvent(QEvent *event)
{
  if(event->type() == QEvent::WindowStateChange)
    setCursor(isFullScreen() ? Qt::BlankCursor : Qt::ArrowCursor);
}

void window::update_title()
{
  const QString title = QString("%1 (%2/%3) — %4")
    .arg("hello world")
    .arg(1).arg(2)
    .arg(m_caption);

  setWindowTitle(title);
}

void window::transform(QPainter &painter,
  const double win_w, const double win_h)
{
  const double zoom = std::min(win_w / 1080, win_h / 720);
  const int real_w = 1080 * zoom;
  const int real_h = 720 * zoom;
  const int offset_x = (win_w - real_w) / 2;
  const int offset_y = (win_h - real_h) / 2;

  painter.translate(offset_x, offset_y);
  painter.scale(zoom, zoom);

  // prevent overflows
  painter.setClipRect(QRect(0, 0, 1080, 720));
}
