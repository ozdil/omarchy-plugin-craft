# Maintainer: Ozan Özdil <ozan@pm.me>
pkgname=omarchy-plugin-craft
pkgver=1.1.0
pkgrel=1
pkgdesc="Unified plugin manager and centralized launcher hub for Omarchy Linux"
arch=('x86_64')
url="https://github.com/ozdil/omarchy-plugin-craft"
license=('MIT')
depends=('glibc')
makedepends=('cargo' 'rust')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=('SKIP')

build() {
  cd "$pkgname-$pkgver"
  cargo build --release --locked
}

package() {
  cd "$pkgname-$pkgver"
  install -Dm755 target/release/plugincraft-engine "$pkgdir/usr/lib/omarchy/plugins/plugin-craft/plugincraft-engine"
  install -Dm755 plugincraft-status "$pkgdir/usr/lib/omarchy/plugins/plugin-craft/plugincraft-status"
  install -Dm755 plugincraft-dashboard "$pkgdir/usr/lib/omarchy/plugins/plugin-craft/plugincraft-dashboard"
  install -Dm644 Panel.qml "$pkgdir/usr/lib/omarchy/plugins/plugin-craft/Panel.qml"
  install -Dm644 manifest.json "$pkgdir/usr/lib/omarchy/plugins/plugin-craft/manifest.json"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
