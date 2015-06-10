#ifndef SFL_DOCTOR_HPP
#define SFL_DOCTOR_HPP

#include <boost/format/format_fwd.hpp>
#include <stack>
#include <vector>

#include "diagnosis.hpp"

#define SFL_ERROR_AT(msg) sfl::doctor::diagnose(sfl::diagnosis::error, msg)

namespace sfl {
  typedef std::vector<diagnosis> diagnosis_bag;

  class doctor {
  public:
    static doctor *instance();
    static void diagnose(const enum diagnosis::level, const std::string &);
    static void diagnose(const enum diagnosis::level, const boost::format &);

    doctor();
    ~doctor();

    const std::vector<diagnosis> &bag() { return m_bag; }

    void add_diagnosis(const diagnosis &dia);

  private:
    static std::stack<doctor *> s_instances;

    diagnosis_bag m_bag;
  };
};

#endif
