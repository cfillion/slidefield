#include "vendor/catch.hpp"

#include <boost/format.hpp>

#include "../src/doctor.hpp"

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
  SFL_DIAGNOSE(diagnosis::note, "should not crash when there are no doctors");

  doctor doc;

  SECTION("error", M) {
    SFL_ERROR_AT("hello world");

    const diagnosis dia = doc.bag().back();
    REQUIRE(dia.level() == diagnosis::error);
    REQUIRE(dia.message() == "hello world");
  }

  REQUIRE(doc.bag().size() == 1);
}
