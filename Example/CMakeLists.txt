add_executable(OldExample OldExample.swift)

# error: 'main' attribute cannot be used in a module that contains top-level code
# note: pass '-parse-as-library' to compiler invocation if this is intentional
target_compile_options(OldExample PUBLIC "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-parse-as-library>")

target_link_libraries(OldExample PUBLIC SlintUI)