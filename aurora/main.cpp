/**
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Точка входа приложения «Трекер Расходов» для ОС Аврора.
 */

#include <flutter/flutter_aurora.h>
#include "generated_plugin_registrant.h"

int main(int argc, char* argv[]) {
    aurora::Initialize(argc, argv);
    aurora::RegisterPlugins();
    aurora::Launch();
    return 0;
}
