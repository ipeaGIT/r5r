tester <- function(mode = "WALK", mode_egress = "WALK", style = "ttm") {
  assign_mode(mode, mode_egress, style)
}

test_that("expects correct modes", {
  expect_error(tester(character()))
  expect_error(tester("oie"))
  expect_error(tester(NA))
  expect_error(tester(mode_egress = c("WALK", "CAR"), style = "ttm"))
  expect_error(tester(mode_egress = NA, style = "dit"))
  expect_error(tester(mode_egress = character(), style = "dit"))
  expect_error(tester(mode_egress = "CAR_PARK"))
})

test_that("raises error when receives either CAR_PARK or BICYCLE_RENT", {
  expect_error(tester("CAR_PARK"))
  expect_error(tester("BICYCLE_RENT"))
})

test_that("raises errors when it cannot disambiguate direct modes (in ttm)", {
  expect_error(tester(c("CAR", "WALK")))
  expect_error(tester(c("CAR", "WALK", "TRANSIT")))
})

test_that("mode_egress is ignored when direct modes are passed to mode", {
  expect_identical(tester("WALK", "WALK"), tester("WALK", "BICYCLE"))
  expect_identical(tester("CAR", "WALK"), tester("CAR", "BICYCLE"))
  expect_identical(
    tester("BICYCLE", "WALK"),
    tester("BICYCLE", "CAR")
  )

  expect_identical(
    tester("CAR", "WALK"),
    list(
      direct_modes = "CAR",
      transit_mode = "",
      access_mode = "CAR",
      egress_mode = ""
    )
  )
})

test_that("walk is set to access_mode when not listed in mode", {
  expect_identical(tester(c("BUS", "WALK"), "WALK"), tester("BUS", "WALK"))

  expect_identical(
    tester("BUS", "WALK"),
    list(
      direct_modes = "WALK",
      transit_mode = "BUS",
      access_mode = "WALK",
      egress_mode = "WALK"
    )
  )

  expect_identical(
    tester(c("BUS", "CAR"), "WALK"),
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
    tester(c("TRANSIT", "WALK"), "WALK"),
    list(
      direct_modes = "WALK",
      transit_mode = paste0(tr_modes, collapse = ";"),
      access_mode = "WALK",
      egress_mode = "WALK"
    )
  )
})

test_that("multiple access and direct modes are accepted in detailed_itin", {
  expect_identical(
    tester(c("WALK", "CAR", "BICYCLE"), "WALK", style = "dit"),
    list(
      direct_modes = paste(c("WALK", "CAR", "BICYCLE"), collapse = ";"),
      transit_mode = "",
      access_mode = paste(c("WALK", "CAR", "BICYCLE"), collapse = ";"),
      egress_mode = ""
    )
  )

  expect_identical(
    tester(c("WALK", "CAR", "BICYCLE", "BUS"), "WALK", style = "dit"),
    list(
      direct_modes = paste(c("WALK", "CAR", "BICYCLE"), collapse = ";"),
      transit_mode = "BUS",
      access_mode = paste(c("WALK", "CAR", "BICYCLE"), collapse = ";"),
      egress_mode = "WALK"
    )
  )
})

test_that("multiple egress modes are accepted in detailed_itin", {
  expect_identical(
    tester(c("WALK", "BUS"), c("WALK", "CAR"), style = "dit"),
    list(
      direct_modes = paste(c("WALK"), collapse = ";"),
      transit_mode = "BUS",
      access_mode = paste(c("WALK"), collapse = ";"),
      egress_mode = paste(c("WALK", "CAR"), collapse = ";")
    )
  )
})
