#include "doctor.hpp"

#include <boost/format.hpp>

using namespace boost;
using namespace sfl;

std::stack<doctor *> doctor::s_instances;

doctor *doctor::instance()
{
  return s_instances.empty() ? 0 : s_instances.top();
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

void doctor::diagnose(const enum diagnosis::level lvl, const std::string &msg)
{
  diagnosis dia(lvl, msg);
  m_bag.push_back(dia);
}

void doctor::diagnose(const enum diagnosis::level level, const format &format)
{
  diagnose(level, format.str());
}
