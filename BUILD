load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library")

cc_library(
    name = "lib",
    srcs = ["hello.cc"],
)

cc_binary(
    name = "hello",
    deps = [":lib"],
    linkstatic = False,
)
