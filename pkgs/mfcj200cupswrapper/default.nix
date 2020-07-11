{ stdenv, fetchurl, mfcj200lpr, makeWrapper}:

stdenv.mkDerivation rec {
  model = "mfcj200";
  name = "${model}cupswrapper";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf100921/${model}cupswrapper-${meta.version}.i386.deb";
    sha256 = "6eed1b268b8652685c9ee26cf5b8dd55574c2b8084fca6792a1c09cfc6ccce7d";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ mfcj200lpr ];

  dontUnpack = true;

  patchPhase = ''
    WRAPPER=cupswrapper/cupswrappermfcj200

    substituteInPlace $WRAPPER \
    --replace /opt "${mfcj200lpr}/opt" \
    --replace /usr "${mfcj200lpr}/usr" \
    --replace /etc "$out/etc"

    substituteInPlace $WRAPPER \
    --replace "\`cp " "\`cp -p " \
    --replace "\`mv " "\`cp -p "
    '';

  buildPhase = ''
    cd brcupsconfpt1
    make all
    cd ..
    '';

  installPhase = ''
    dpkg-deb -x $src $out

    TARGETFOLDER=$out/opt/brother/Printers/mfcj200/cupswrapper/
    mkdir -p $out/opt/brother/Printers/mfcj200/cupswrapper/

    cp brcupsconfpt1/brcupsconfpt1 $TARGETFOLDER
    cp cupswrapper/cupswrappermfcj200 $TARGETFOLDER/
    cp PPD/brother_mfcj200_printer_en.ppd $TARGETFOLDER/
    '';

  cleanPhase = ''
    cd brcupsconfpt1
    make clean
    '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother MFC-J200 CUPS wrapper driver";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_us_eu_as&os=128";
    maintainers = [ "dawid.jarosz@gmail.com" ];
    version = "3.0.0-1";
  };
}
