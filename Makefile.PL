use inc::Module::Install;

name('POE-Component-IRC-Onjoin');
version_from('lib/POE/Component/IRC/Onjoin.pm');
abstract('provides IRC moved message & onjoin services');
author('Adam J. Foxson <afoxson@pobox.com>');
license('gpl');
requires('POE::Component::IRC' => '2.9');
include('ExtUtils::AutoInstall');
check_nmake();
auto_install();

&Meta->write;
&Build->write if lc($0) eq 'build.pl';
&Makefile->write if lc($0) eq 'makefile.pl';
