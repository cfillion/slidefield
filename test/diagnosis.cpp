#include "vendor/catch.hpp"
#include "../src/diagnosis.hpp"

using namespace sfl;

static const char *M = "[diagnosis]";

TEST_CASE("diagnosis accessors", M) {
  const diagnosis dia(diagnosis::note, "hello world");
  REQUIRE(dia.level() == diagnosis::note);
  REQUIRE(dia.message() == "hello world");
}

TEST_CASE("compare diagnosis", M) {
  const diagnosis dia(diagnosis::note, "hello world");

  SECTION("same") {
    REQUIRE(dia == dia);
    REQUIRE_FALSE(dia != dia);
  }

  SECTION("different level") {
    const diagnosis different_level(diagnosis::error, "hello world");
    REQUIRE_FALSE(dia == different_level);
    REQUIRE(dia != different_level);
  }

  SECTION("different message") {
    const diagnosis different_message(diagnosis::note, "chunky bacon");
    REQUIRE_FALSE(dia == different_message);
    REQUIRE(dia != different_message);
  }
}
