#include "location.hpp"

using namespace sfl;

location::location(const sfl::context &c)
  : m_context(c)
{
}

bool sfl::operator==(const context &left, const context &right)
{
  return left.doctor == right.doctor;
}

bool sfl::operator!=(const context &left, const context &right)
{
  return !(left == right);
}

bool sfl::operator==(const location &left, const location &right)
{
  return left.context() == right.context();
}

bool sfl::operator!=(const location &left, const location &right)
{
  return !(left == right);
}
