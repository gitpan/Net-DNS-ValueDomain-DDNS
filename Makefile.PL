use 5.008007;
use inc::Module::Install;

name('Net-DNS-ValueDomain-DDNS');
version_from('lib/Net/DNS/ValueDomain/DDNS.pm');
license('perl');

requires('LWP::UserAgent');
recommends('Crypt::SSLeay');

auto_include();
auto_install();

&WriteAll;
