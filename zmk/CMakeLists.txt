if(CONFIG_ROLLINO_BALL_FUSION)
  zephyr_library()
  zephyr_library_sources(src/ball_fusion.c)
  # ZMK's own headers (zmk/ble.h), for the profile gestures
  zephyr_library_include_directories(${APPLICATION_SOURCE_DIR}/include)
endif()
