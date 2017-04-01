# Copyright 2017 The Bazel Authors. All rights reserved.
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

"""Utilities for testing Apple rules."""


def apple_shell_test(name,
                     src,
                     configurations={},
                     data=None,
                     deps=None,
                     tags=None,
                     **kwargs):
  """Creates test targets for an Apple shell integration test script.

  This macro allows for the easy creation of multiple test targets that each
  run the given test script, but with different configuration arguments passed
  into the test's `bazel` invocations. For example:

      apple_shell_test(
          name = "my_test",
          src = "my_test.sh",
          configurations = {
              "simulator": ["--ios_multi_cpus=x86_64"],
              "device": ["--ios_multi_cpus=arm64,armv7"],
          },
      )

  The above snippet would create three targets, named based on the
  configurations:

  * my_test.simulator: applies "--ios_multi_cpus=x86_64" to all builds.
  * my_test.device: applies "--ios_multi_cpus=arm64,armv7" to all builds.
  * my_test: A test suite containing the above tests.

  Args:
    name: The name of the test suite and prefix to use for each of the
        individual configuration tests.
    src: The shell script to run.
    configurations: A dictionary with the configurations for which the test
        should be run.
    data: Additional data dependencies to pass to the test targets.
    deps: Additional dependencies to pass to the test targets.
    tags: Additional tags to set on the test targets. "requires-darwin" is
        automatically added.
    **kwargs: Additional attribute values to apply to each test target.
  """
  if not configurations:
    fail("You must specify at least one configuration in the " +
         "'configurations' attribute.")

  for (config_name, config_options) in configurations.items():
    native.sh_test(
        name = "%s.%s" % (name, config_name),
        srcs = ["apple_shell_testrunner.sh"],
        args = [
            src,
        ] + config_options,
        data = [
            src,
            "//apple:for_bazel_tests",
            "//apple/bundling:for_bazel_tests",
            "//test:apple_shell_testutils.sh",
            "//test/testdata/provisioning:BUILD",
            "//test/testdata/provisioning:integration_testing.mobileprovision",
            "//test:unittest.bash",
        ] + (data or []),
        deps = deps or [],
        tags = ["requires-darwin"] + (tags or []),
        **kwargs
    )

  native.test_suite(
      name = name,
      tests = [":%s.%s" % (name, config_name)
               for config_name in configurations.keys()],
  )