#include "vendor/catch.hpp"

#include <boost/format.hpp>

#include "../src/diagnosis.hpp"
#include "../src/doctor.hpp"

using namespace sfl;

static const char *M = "[doctor]";

TEST_CASE("emit diagnosis", M) {
  CHECK(doctor::bag().empty());

  doctor doc;

  SECTION("error from string") {
    const diagnosis dia = doc.error_at("hello world");
    REQUIRE(dia.level() == diagnosis::error);
    REQUIRE(dia.message() == "hello world");
  }

  SECTION("error from format") {
    const diagnosis dia = doc.error_at(boost::format("hello world"));
    REQUIRE(dia.level() == diagnosis::error);
    REQUIRE(dia.message() == "hello world");
  }

  CHECK(doctor::bag().size() == 1);
  doctor::reset_bag();
}
