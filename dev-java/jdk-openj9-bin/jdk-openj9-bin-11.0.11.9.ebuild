# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit java-vm-2 toolchain-funcs
SLOT="${PV%%[.+]*}"

openj9v=0.26.0
actualPkgVer=11.0.11+9_openj9-0.26.0

DESCRIPTION="Prebuilt Java JDK binaries provided by AdoptOpenJDK, with OpenJ9 VM"

HOMEPAGE="https://adoptopenjdk.net"

LICENSE="EPL-2 GPL-2-with-classpath-exception"
KEYWORDS="~amd64"

IUSE="source alsa cups headless-awt"

SRC_URI="https://github.com/AdoptOpenJDK/openjdk${SLOT}-binaries/releases/download/jdk-${actualPkgVer}/OpenJDK${SLOT}U-jdk_x64_linux_openj9_${actualPkgVer//+/_}.tar.gz" # I won't be fixing this any time soon.

QA_PREBUILT="*"

COMMON_DEPEND="media-libs/freetype:2=
			media-libs/harfbuzz:=
			media-libs/fontconfig
			sys-libs/zlib"

RDEPEND="${COMMON_DEPEND}
		>=sys-apps/baselayout-java-0.1.0-r1
		>=sys-libs/glibc-2.12:*
		!headless-awt? (
			x11-libs/libX11
			x11-libs/libXext
			x11-libs/libXi
			x11-libs/libXrandr
			x11-libs/libXrender
			x11-libs/libXt
			x11-libs/libXtst
		)
		alsa? ( media-libs/alsa-lib )
		cups? ( net-print/cups )"



pkg_pretend() {
	if [[ "$(tc-is-softfloat)" != "no" ]]; then
		die "These binaries require a hardfloat system."
	fi
}

S="${WORKDIR}/jdk-11.0.11+9"

src_install() {
	local dest="/opt/${P}"
	local ddest="${ED%/}/${dest#/}"

	# on macOS if they would exist they would be called .dylib, but most
	# importantly, there are no different providers, so everything
	# that's shipped works.
	if [[ ${A} != *_mac_* ]] ; then
		# Not sure why they bundle this as it's commonly available and they
		# only do so on x86_64. It's needed by libfontmanager.so. IcedTea
		# also has an explicit dependency while Oracle seemingly dlopens it.
		rm -vf lib/libfreetype.so || die

		# prefer system copy # https://bugs.gentoo.org/776676
		rm -vf lib/libharfbuzz.so || die

		# Oracle and IcedTea have libjsoundalsa.so depending on
		# libasound.so.2 but AdoptOpenJDK only has libjsound.so. Weird.
		if ! use alsa ; then
			rm -v lib/libjsound.* || die
		fi

		if use headless-awt ; then
			rm -v lib/lib*{[jx]awt,splashscreen}* || die
		fi
	fi

	if ! use source ; then
		rm -v lib/src.zip || die
	fi

	rm -v lib/security/cacerts || die
	dosym ../../../../etc/ssl/certs/java/cacerts \
		"${dest}"/lib/security/cacerts

	dodir "${dest}"
	cp -pPR * "${ddest}" || die

	# provide stable symlink
	dosym "${P}" "/opt/${PN}-${SLOT}"

	use gentoo-vm && java-vm_install-env "${FILESDIR}"/${PN}-${SLOT}.env.sh
	java-vm_set-pax-markings "${ddest}"
	java-vm_revdep-mask
	java-vm_sandbox-predict /dev/random /proc/self/coredump_filter
}

pkg_postinst() {
	java-vm-2_pkg_postinst
	einfo "The experimental gentoo-vm USE flag is not supported for this build,"
	einfo "so this JDK will not be recognised by the system; e.g. simply calling"
	einfo "\"java\" will launch a different JVM. This is necessary until Gentoo"
	einfo "fully supports Java 11. This JDK must therefore be invoked using its"
	einfo "absolute location under ${EPREFIX}/opt/${P}."

}