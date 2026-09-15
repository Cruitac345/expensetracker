%global __provides_exclude_from ^%{_datadir}/%{name}/lib/.*$
%global __requires_exclude ^lib(dconf|flutter-embedder|maliit-glib|.+_platform_plugin)\.so.*$

Name:       ru.auroraos.expense_tracker
Summary:    Трекер Расходов
Version:    1.0.0
Release:    1
License:    BSD-3-Clause
Source0:    %{name}-%{version}.tar.zst

BuildRequires: cmake
BuildRequires: ninja

%description
Учёт личных и служебных расходов: траты с чеками, категории,
командировки, импорт CSV и дашборд с диаграммами.

%prep
%autosetup

%build
%cmake -GNinja -DCMAKE_BUILD_TYPE=%{_flutter_build_type} -DPSDK_VERSION=%{_flutter_psdk_version} -DPSDK_MAJOR=%{_flutter_psdk_major}
%ninja_build

%install
%ninja_install

%files
%{_bindir}/%{name}
%{_datadir}/%{name}/*
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
