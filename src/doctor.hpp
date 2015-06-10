#ifndef SFL_DOCTOR_HPP
#define SFL_DOCTOR_HPP

#include <boost/format/format_fwd.hpp>
#include <vector>

namespace sfl {
  class diagnosis;

  class doctor {
  public:
    static const std::vector<diagnosis> &bag() { return s_bag; }
    static void reset_bag() { s_bag.clear(); }

    diagnosis error_at(const std::string &message) const;
    diagnosis error_at(const boost::format &message) const;

  private:
    static std::vector<diagnosis> s_bag;

    void emit(const diagnosis &dia) const;
  };
};

#endif
