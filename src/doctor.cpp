#include "doctor.hpp"

#include <boost/format.hpp>

#include "errors.hpp"

using namespace sfl;

void sfl::error_at(const location &location, const boost::format &format)
{
  error_at(location, format.str());
}

void sfl::error_at(const location &location, const std::string &message)
{
  diagnose_at(location, message, diagnosis::error);
}

void sfl::diagnose_at(const location &location,
  const std::string &message, const enum diagnosis::level level)
{
  doctor *doc = location.doctor();

  if(!doc)
    throw missing_doctor();

  doc->add_diagnosis(message, level, location);
}

void doctor::add_diagnosis(const std::string &message,
  const enum diagnosis::level level, const sfl::location &location)
{
  add_diagnosis(diagnosis(level, message, location));
}

void doctor::add_diagnosis(const diagnosis &dia)
{
  m_bag.push_back(dia);
}
