#include "diagnosis.hpp"

#include <cstring>

bool sfl::operator==(const diagnosis &left, const diagnosis &right)
{
  return left.level() == right.level() &&
    left.message() == right.message();
}

bool sfl::operator!=(const diagnosis &left, const diagnosis &right)
{
  return !(left == right);
}

std::ostream &sfl::operator<<(std::ostream &os, const diagnosis &ds)
{
  os << ds.message();
  return os;
}
