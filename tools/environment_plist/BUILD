load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

licenses(["notice"])

sh_binary(
    name = "environment_plist",
    # Through the label_flag rather than a canonical repo name, which would
    # only resolve when the module setting it is the one being built.
    data = ["//apple:sdk_tool_files"],
    srcs = ["environment_plist.sh"],
    visibility = [
        "//apple/internal:__pkg__",
    ],
)

# Consumed by bazel tests.
filegroup(
    name = "for_bazel_tests",
    testonly = True,
    srcs = glob(["**"]),
    visibility = [
        "//tools:__pkg__",
    ],
)
