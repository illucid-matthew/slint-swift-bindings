list(APPEND SlintUI_LIB_SOURCE_FILES
  Slint.swift
  AsyncChannel.swift
  WrappedClosure.swift
  Actor.swift
  EventLoop.swift
  Timer.swift
  VTable.swift
)

add_library(SlintUI ${SlintUI_LIB_SOURCE_FILES})

# 🚨 For some reason, this must be PUBLIC
target_link_libraries(SlintUI PUBLIC
  Slint
)