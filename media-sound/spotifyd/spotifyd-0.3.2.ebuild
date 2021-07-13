# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Short one-line description of this package.
DESCRIPTION="A Spotify daemon"


HOMEPAGE="https://github.com/Spotifyd/spotifyd"

SRC_URI="https://github.com/Spotifyd/spotifyd/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
		https://raw.githubusercontent.com/BGazotti/gazports/main/media-sound/spotifyd/files/spotifyd"

# Source directory; the dir where the sources can be found (automatically
# unpacked) inside ${WORKDIR}.  The default value for S is ${WORKDIR}/${P}
# If you don't need to change it, leave the S= line out of the ebuild
# to keep it tidy.
#S="${WORKDIR}/${P}"

LICENSE="GPL-3"

SLOT="0"

KEYWORDS="~amd64"

# Comprehensive list of any and all USE flags leveraged in the ebuild,
# with some exceptions, e.g., ARCH specific flags like "amd64" or "ppc".
# Not needed if the ebuild doesn't use any USE flags.
IUSE="pulseaudio alsa portaudio dbus -systemd"

RDEPEND="dbus? ( >=sys-apps/dbus-1.12.20-r1 )
		alsa? ( >=media-libs/alsa-lib-1.2.5.1 )
		pulseaudio? ( >=media-sound/pulseaudio-13.0-r1 )
		portaudio? ( media-libs/portaudio )
		>=media-libs/libogg-1.3.5"

# Build-time dependencies that need to be binary compatible with the system
# being built (CHOST). These include libraries that we link against.
# The below is valid if the same run-time depends are required to compile.
DEPEND="" 

BDEPEND=">=dev-lang/rust-1.53.0"


src_configure() {
	# Perform cargo test as suggested
	cargo test --release --locked --target-dir=target || die
}

src_compile() {

	# set compile features based on USE flags
	RTPARAMS=
	if ( use alsa ) then
		RTPARAMS="${RTPARAMS} alsa_backend"
	fi
	if ( use pulseaudio ) then
		RTPARAMS="${RTPARAMS} pulseaudio_backend"
	fi
	if ( use portaudio ) then
		RTPARAMS="${RTPARAMS} portaudio_backend"
	fi
	if ( use dbus ) then
		RTPARAMS="${RTPARAMS} dbus_keyring,dbus_mpris"
	fi
	RTPARAMS="${RTPARAMS## }" # removing trailing whitespace
	cargo build --release --features ${RTPARAMS// /,} # formatting for compile params
}

src_install() {
	# install the .service file if systemd (work/contrib/spotifyd.service)
	if ( use systemd )  then		
		USERSERVICEDIR=/etc/systemd/user/
		einfo "Copying systemd service file to ${USERSERVICEDIR}" 
		dodir $USERSERVICEDIR
		insinto $USERSERVICEDIR
		doins "${S}"/contrib/spotifyd.service
	fi
	# install spotifyd binary
	dobin "${S}"/target/release/spotifyd
}

pkg_postinst() {
	echo "Cleaning up the rust..."
	rm -r "${S}"/target/release/build
	rm -r "${S}"/target/release/deps
	einfo "You'll need to provide some info to the spotifyd process in order to play songs."
	einfo "This can be done by starting spotifyd with the proper arguments or by"
	einfo "setting up a configuration file at ~/.config/spotifyd ."
	elog "See https://spotifyd.github.io/spotifyd/config/File.html for more information."
}
