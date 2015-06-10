#ifndef SFL_DOCTOR_HPP
#define SFL_DOCTOR_HPP

#include <boost/format/format_fwd.hpp>
#include <stack>
#include <vector>

#include "diagnosis.hpp"

#define SFL_ERROR_AT(msg) SFL_DIAGNOSE(sfl::diagnosis::error, msg)
#define SFL_DIAGNOSE(lvl, msg) if(sfl::doctor::instance()) \
  sfl::doctor::instance()->diagnose(lvl, msg)

namespace sfl {
  typedef std::vector<diagnosis> diagnosis_bag;

  class doctor {
  public:
    static doctor *instance();

    doctor();
    ~doctor();

    const std::vector<diagnosis> &bag() { return m_bag; }

    void diagnose(const enum diagnosis::level lvl, const std::string &message);
    void diagnose(const enum diagnosis::level lvl, const boost::format &format);

  private:
    static std::stack<doctor *> s_instances;

    diagnosis_bag m_bag;
  };
};

#endif
