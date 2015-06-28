#include "vendor/catch.hpp"

#include "../src/errors.hpp"
#include "../src/registry.hpp"

using namespace sfl;

static const char *M = "[registry]";

TEST_CASE("definition name and user data", M) {
  const definition a{"foo"};
  REQUIRE(a.name() == "foo");
  REQUIRE(a.user_data() == -1);

  const definition b{"bar", 42};
  REQUIRE(b.name() == "bar");
  REQUIRE(b.user_data() == 42);
}

TEST_CASE("add to registry", M) {
  registry reg;
  REQUIRE(reg.count("foo") == 0);

  reg.add(definition{"foo"});

  REQUIRE(reg.count("foo") == 1);
  REQUIRE(reg.at("foo").name() == "foo");
}

TEST_CASE("add duplicate", M) {
  registry reg;
  reg.add(definition{"foo"});

  REQUIRE_THROWS_AS({
    reg.add(definition{"foo"});
  }, duplicate_definition);

  REQUIRE(reg.count("foo") == 1);
}

TEST_CASE("unknown definition", M) {
  const registry reg;
  REQUIRE(reg.count("foo") == 0);

  REQUIRE_THROWS_AS({
    reg.at("foo");
  }, std::out_of_range);
}
