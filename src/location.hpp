#ifndef SFL_LOCATION_HPP
#define SFL_LOCATION_HPP

#include <boost/format/format_fwd.hpp>

namespace sfl {
  class doctor;
  class registry;

  struct context {
    sfl::doctor *doctor;
    sfl::registry *registry;
  };

  class location {
  public:
    location(const context &c = sfl::context());

    doctor *doctor() const { return m_context.doctor; }
    registry *registry() const { return m_context.registry; }

  private:
    const context &context() const { return m_context; }
    sfl::context m_context;

    friend bool operator==(const location &left, const location &right);
    friend bool operator!=(const location &left, const location &right);
  };

  bool operator==(const context &left, const context &right);
  bool operator!=(const context &left, const context &right);

  bool operator==(const location &left, const location &right);
  bool operator!=(const location &left, const location &right);
};

#endif
