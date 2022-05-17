test_that("expects correct modes", {
  expect_error(select_mode(character(), "WALK"))
  expect_error(select_mode("oie", "WALK"))
  expect_error(select_mode("WALK", c("WALK", "CAR")))
  expect_error(select_mode("WALK", "CAR_PARK"))
})

test_that("raises error when receives either CAR_PARK or BICYCLE_RENT", {
  expect_error(select_mode("CAR_PARK", "WALK"))
  expect_error(select_mode("BICYCLE_RENT", "WALK"))
})

test_that("raises errors when it cannot disambiguate direct modes", {
  expect_error(select_mode(c("CAR", "WALK"), "WALK"))
  expect_error(select_mode(c("CAR", "WALK", "TRANSIT"), "WALK"))
})

test_that("mode_egress is ignored when direct modes are passed to mode", {
  expect_identical(select_mode("WALK", "WALK"), select_mode("WALK", "BICYCLE"))
  expect_identical(select_mode("CAR", "WALK"), select_mode("CAR", "BICYCLE"))
  expect_identical(
    select_mode("BICYCLE", "WALK"),
    select_mode("BICYCLE", "CAR")
  )

  expect_identical(
    select_mode("CAR", "WALK"),
    list(
      direct_modes = "CAR",
      transit_mode = "",
      access_mode = "CAR",
      egress_mode = ""
    )
  )
})

test_that("walk is set to access_mode when not listed in mode", {
  expect_identical(
    select_mode(c("BUS", "WALK"), "WALK"),
    select_mode("BUS", "WALK")
  )

  expect_identical(
    select_mode("BUS", "WALK"),
    list(
      direct_modes = "WALK",
      transit_mode = "BUS",
      access_mode = "WALK",
      egress_mode = "WALK"
    )
  )

  expect_identical(
    select_mode(c("BUS", "CAR"), "WALK"),
    list(
      direct_modes = "CAR",
      transit_mode = "BUS",
      access_mode = "CAR",
      egress_mode = "WALK"
    )
  )
})

test_that("all pt modes are passed to transit_modes when TRANSIT is present", {
  tr_modes <- c(
    "TRANSIT",
    "TRAM",
    "SUBWAY",
    "RAIL",
    "BUS",
    "FERRY",
    "CABLE_CAR",
    "GONDOLA",
    "FUNICULAR"
  )

  expect_identical(
    select_mode(c("TRANSIT", "WALK"), "WALK"),
    list(
      direct_modes = "WALK",
      transit_mode = paste0(tr_modes, collapse = ";"),
      access_mode = "WALK",
      egress_mode = "WALK"
    )
  )
})
