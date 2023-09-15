// Copyright (C) 2023 Dingyuan Zhang <lxz@mkacg.com>.
// SPDX-License-Identifier: Apache-2.0 OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only

#pragma once

#include <QGuiApplication>

class FakeSession : public QGuiApplication {
    Q_OBJECT
public:
    explicit FakeSession(int argc, char* argv[]);
};
