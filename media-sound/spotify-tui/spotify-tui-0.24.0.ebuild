# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="A Spotify terminal client"

HOMEPAGE="https://github.com/Rigellute/spotify-tui"

SRC_URI="https://github.com/Rigellute/spotify-tui/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

# Source directory; the dir where the sources can be found (automatically
# unpacked) inside ${WORKDIR}.  The default value for S is ${WORKDIR}/${P}
# If you don't need to change it, leave the S= line out of the ebuild
# to keep it tidy.
#S="${WORKDIR}/${P}"

LICENSE="MIT"

SLOT="0"

KEYWORDS="~amd64"

RDEPEND=""

# Build-time dependencies that need to be binary compatible with the system
# being built (CHOST). These include libraries that we link against.
DEPEND=">=dev-libs/openssl-1" 

BDEPEND=">=dev-lang/rust-1.53.0"


src_configure() {
	echo vars
}

src_compile() {
	cargo build --release --target-dir "target/"
}

src_install() {

	# install documentation
	dodoc $S/README.md 
	# install spt binary
	dobin "${S}"/target/release/spt
}

pkg_postinst() {
	echo "Cleaning up the rust..."
	rm -r "${S}"/target/release/build
	rm -r "${S}"/target/release/deps
	elog "The spotify-tui executable is called spt."
	elog "See /usr/share/doc/${PF}/README.md for information about configurating and running spotify-tui."
}
