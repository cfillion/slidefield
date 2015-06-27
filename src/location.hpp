#ifndef SFL_LOCATION_HPP
#define SFL_LOCATION_HPP

#include <boost/format/format_fwd.hpp>

namespace sfl {
  class doctor;

  struct context {
    sfl::doctor *doctor;
  };

  class location {
  public:
    location(const context &c = sfl::context());

    const context &context() const { return m_context; }
    doctor *doctor() const { return m_context.doctor; }

  private:
    sfl::context m_context;
  };

  bool operator==(const context &left, const context &right);
  bool operator!=(const context &left, const context &right);

  bool operator==(const location &left, const location &right);
  bool operator!=(const location &left, const location &right);
};

#endif
