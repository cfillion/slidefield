#include "doctor.hpp"

#include <boost/format.hpp>

#include "errors.hpp"

using namespace boost;
using namespace sfl;

std::stack<doctor *> doctor::s_instances;

doctor *doctor::instance()
{
  return s_instances.empty() ? 0 : s_instances.top();
}

void doctor::diagnose(const enum diagnosis::level lvl, const std::string &msg)
{
  const diagnosis dia(lvl, msg);

  doctor *doc = doctor::instance();
  if(!doc)
    throw missing_doctor();

  doc->add_diagnosis(dia);
}

void doctor::diagnose(const enum diagnosis::level level, const format &format)
{
  diagnose(level, format.str());
}

doctor::doctor()
{
  s_instances.push(this);
}

doctor::~doctor()
{
  assert(s_instances.top() == this);
  s_instances.pop();
}

void doctor::add_diagnosis(const diagnosis &dia)
{
  m_bag.push_back(dia);
}
