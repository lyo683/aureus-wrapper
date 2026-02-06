# syntax=docker/dockerfile:1.7
FROM webkul/aureuserp:latest

WORKDIR /home/aureuserp/aureuserp

RUN <<'EOF'
set -e

# 1) trustProxies를 bootstrap/app.php에 고정
cp bootstrap/app.php bootstrap/app.php.bak 2>/dev/null || true

cat > bootstrap/app.php <<'PHP'
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
PHP

# 2) favicon/logo는 상대경로로 고정 (Mixed Content 제거)
perl -pi -e "s/->favicon\(asset\('images\/favicon\.ico'\)\)/->favicon('\/images\/favicon.ico')/g" \
  app/Providers/Filament/AdminPanelProvider.php \
  app/Providers/Filament/CustomerPanelProvider.php || true

perl -pi -e "s/asset\('images\/logo-light\.svg'\)/'\/images\/logo-light.svg'/g; s/asset\('images\/logo-dark\.svg'\)/'\/images\/logo-dark.svg'/g" \
  app/Providers/Filament/AdminPanelProvider.php \
  app/Providers/Filament/CustomerPanelProvider.php || true

# 3) 캐시 클리어
php artisan optimize:clear >/dev/null 2>&1 || true
EOF
