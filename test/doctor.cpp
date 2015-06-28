#include "vendor/catch.hpp"

#include <boost/format.hpp>

#include "../src/doctor.hpp"
#include "../src/errors.hpp"

using namespace sfl;

static const char *M = "[doctor]";

TEST_CASE("make a diagnosis", M) {
  doctor doc;

  CHECK(doc.bag().empty());
  doc.add_diagnosis("hello world", diagnosis::note);
  REQUIRE(doc.bag().size() == 1);

  const diagnosis dia = doc.bag().back();
  REQUIRE(dia.level() == diagnosis::note);
  REQUIRE(dia.message() == "hello world");
}

TEST_CASE("diagnosis shortcuts", M) {
  doctor doc;
  const location loc({&doc, 0});
  enum diagnosis::level match_level;

  SECTION("error from string", M) {
    error_at(loc, "hello world");
    match_level = diagnosis::error;
  }

  SECTION("error from format", M) {
    error_at(loc, boost::format("hello %s") % "world");
    match_level = diagnosis::error;
  }

  REQUIRE(doc.bag().size() == 1);

  const diagnosis dia = doc.bag().back();
  REQUIRE(dia.message() == "hello world");
  REQUIRE(dia.level() == match_level);
  REQUIRE(dia.location() == loc);
}

TEST_CASE("missing doctor", M) {
  location loc;

  REQUIRE_THROWS_AS({
    diagnose_at(loc, "crash", diagnosis::error);
  }, missing_doctor);
}
