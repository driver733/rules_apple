# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Stub binary creation support methods."""

load(
    "@apple_support//lib:apple_support.bzl",
    "apple_support",
)
load(
    "@bazel_skylib//lib:shell.bzl",
    "shell",
)
load(
    "//apple/internal:intermediates.bzl",
    "intermediates",
)
load(
    "//apple/internal:shared_environment.bzl",
    "shared_environment",
)

def _create_stub_binary(
        *,
        actions,
        archs_for_lipo = [],
        output_discriminator = None,
        platform_prerequisites,
        rule_label,
        sdk_tool_files = [],
        xcode_stub_path):
    """Returns a symlinked stub binary from the Xcode distribution.

    Args:
        actions: The actions provider from `ctx.actions`.
        archs_for_lipo: A list of strings representing archs to lipo the stub binary against if
            required of the target platform. If not specified, the stub binary will instead be
            copied to its destination.
        output_discriminator: A string to differentiate between different target intermediate files
            or `None`.
        platform_prerequisites: Struct containing information on the platform being targeted.
        rule_label: The label of the target being analyzed.
        xcode_stub_path: The Xcode SDK root relative path to where the stub binary is to be copied
            from.

    Returns:
        A File reference to the stub binary artifact.
    """
    binary_artifact = intermediates.file(
        actions = actions,
        target_name = rule_label.name,
        output_discriminator = output_discriminator,
        file_name = "StubBinary",
    )

    if archs_for_lipo:
        if len(archs_for_lipo) == 1:
            lipo_args = "-thin " + archs_for_lipo[0]
        else:
            lipo_args = " ".join(["-extract " + a for a in archs_for_lipo])
        apple_support.run_shell(
            actions = actions,
            command = (
                "SDKROOT=\"$DEVELOPER_DIR/Platforms/$APPLE_SDK_PLATFORM.platform/Developer/SDKs/$APPLE_SDK_PLATFORM.sdk\" && " +
                "mkdir -p {dir} && \"$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo\" \"$SDKROOT/{stub}\" {args} -output {out}"
            ).format(
                dir = shell.quote(binary_artifact.dirname),
                stub = xcode_stub_path,
                args = lipo_args,
                out = shell.quote(binary_artifact.path),
            ),
            execution_requirements = {"no-sandbox": "1"},
            mnemonic = "AppleLipoExtract",
            outputs = [binary_artifact],
            apple_fragment = platform_prerequisites.apple_fragment,
            xcode_config = platform_prerequisites.xcode_version_config,
        )
    else:
        # TODO(b/79323243): Replace this with a symlink instead of a hard copy.
        apple_support.run_shell(
            actions = actions,
            apple_fragment = platform_prerequisites.apple_fragment,
            env = shared_environment.default_env,
            command = "cp -f \"$SDKROOT/{xcode_stub_path}\" {output_path}".format(
                output_path = binary_artifact.path,
                xcode_stub_path = xcode_stub_path,
            ),
            mnemonic = "CopyStubExecutable",
            outputs = [binary_artifact],
            progress_message = "Copying stub executable for %s" % (rule_label),
            xcode_config = platform_prerequisites.xcode_version_config,
        )
    return binary_artifact

stub_support = struct(
    create_stub_binary = _create_stub_binary,
)
