requires 'Coro';
requires 'Net::Server::Coro', '0.5';
requires 'Plack', '0.99';
requires 'perl', '5.008001';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.42';
    requires 'Test::More';
};
