list(APPEND SlintUI_LIB_SOURCE_FILES
  Slint.swift

  # Runtime
  Runtime/AsyncChannel.swift
  Runtime/EventLoop.swift
  Runtime/WrappedClosure.swift
  Runtime/Actor.swift

  # Core library types
  Core/Timer.swift
  Core/Callback.swift
)

add_library(SlintUI ${SlintUI_LIB_SOURCE_FILES})

# 🚨 For some reason, this must be PUBLIC
target_link_libraries(SlintUI PUBLIC
  Slint
)