#include "doctor.hpp"

#include <boost/format.hpp>

#include "diagnosis.hpp"

using namespace boost;
using namespace sfl;

std::vector<diagnosis> doctor::s_bag;

diagnosis doctor::error_at(const std::string &message) const
{
  diagnosis dia(diagnosis::error, message);
  emit(dia);
  return dia;
}

diagnosis doctor::error_at(const format &message) const
{
  return error_at(message.str());
}

void doctor::emit(const diagnosis &dia) const
{
  s_bag.push_back(dia);
}
