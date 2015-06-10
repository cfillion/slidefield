#include "vendor/catch.hpp"

#include <boost/format.hpp>

#include "../src/doctor.hpp"
#include "../src/errors.hpp"

using namespace sfl;

static const char *M = "[doctor]";

TEST_CASE("make a diagnosis", M) {
  doctor doc;

  CHECK(doc.bag().empty());

  SECTION("from string") {
    doc.diagnose(diagnosis::note, "hello world");

    const diagnosis dia = doc.bag().back();
    REQUIRE(dia.level() == diagnosis::note);
    REQUIRE(dia.message() == "hello world");
  }

  SECTION("from format") {
    doc.diagnose(diagnosis::note, "hello world");

    const diagnosis dia = doc.bag().back();
    REQUIRE(dia.level() == diagnosis::note);
    REQUIRE(dia.message() == "hello world");
  }

  REQUIRE(doc.bag().size() == 1);
}

TEST_CASE("diagnosis shortcuts", M) {
  doctor doc;

  SECTION("error", M) {
    SFL_ERROR_AT("hello world");

    const diagnosis dia = doc.bag().back();
    REQUIRE(dia.level() == diagnosis::error);
    REQUIRE(dia.message() == "hello world");
  }

  REQUIRE(doc.bag().size() == 1);
}

TEST_CASE("missing doctor", M) {
  REQUIRE(doctor::instance() == 0);

  REQUIRE_THROWS_AS({
    doctor::diagnose(diagnosis::error, "crash");
  }, missing_doctor);
}
