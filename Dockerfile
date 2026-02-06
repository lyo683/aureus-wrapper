FROM webkul/aureuserp:latest

WORKDIR /home/aureuserp/aureuserp

# Laravel 11+ : Reverse proxy(HTTPS) 뒤에서 X-Forwarded-* 신뢰하도록 설정
RUN cp bootstrap/app.php bootstrap/app.php.bak || true
RUN bash -lc 'cat > bootstrap/app.php <<'\''PHP'\''
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->trustProxies(
            at: '*',
            headers: Request::HEADER_X_FORWARDED_FOR |
                Request::HEADER_X_FORWARDED_HOST |
                Request::HEADER_X_FORWARDED_PORT |
                Request::HEADER_X_FORWARDED_PROTO |
                Request::HEADER_X_FORWARDED_AWS_ELB
        );
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
PHP'

# favicon/logo는 절대경로(http)로 나오는 문제를 없애기 위해 상대경로로 고정
RUN perl -pi -e "s/->favicon\\(asset\\('images\\/favicon\\.ico'\\)\\)/->favicon('\\/images\\/favicon.ico')/g" \
  app/Providers/Filament/AdminPanelProvider.php \
  app/Providers/Filament/CustomerPanelProvider.php || true

RUN perl -pi -e "s/asset\\('images\\/logo-light\\.svg'\\)/'\\/images\\/logo-light.svg'/g; s/asset\\('images\\/logo-dark\\.svg'\\)/'\\/images\\/logo-dark.svg'/g" \
  app/Providers/Filament/AdminPanelProvider.php \
  app/Providers/Filament/CustomerPanelProvider.php || true

RUN php artisan optimize:clear || true
