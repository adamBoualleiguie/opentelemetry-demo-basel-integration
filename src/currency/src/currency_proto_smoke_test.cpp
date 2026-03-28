// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

#include <demo.pb.h>
#include <gtest/gtest.h>

namespace
{
TEST(CurrencyProtoSmoke, DemoEmptyDefaultConstructed)
{
  oteldemo::Empty empty;
  (void)empty;
  EXPECT_TRUE(true);
}
} // namespace
