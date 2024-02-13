list(APPEND SlintUI_LIB_SOURCE_FILES
  Slint.swift
  AsyncChannel.swift
  SlintActor.swift
  EventLoop.swift
  Timer.swift
)

add_library(SlintUI ${SlintUI_LIB_SOURCE_FILES})

# 🚨 For some reason, this must be PUBLIC
target_link_libraries(SlintUI PUBLIC
  Slint
)