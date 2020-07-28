{ stdenv, fetchurl, mfcj200lpr, makeWrapper, gnused, gnugrep, coreutils, dpkg }:

let
  model = "mfcj200";
in
stdenv.mkDerivation rec {
  name = "${model}cupswrapper-${meta.version}";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf100921/${name}.i386.deb";
    sha256 = "6eed1b268b8652685c9ee26cf5b8dd55574c2b8084fca6792a1c09cfc6ccce7d";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];
  buildInputs = [ mfcj200lpr ];

  phases = [ "installPhase" ];

  installPhase = ''
    dpkg-deb -x $src $out

    WRAPPER=$out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model}

    substituteInPlace $WRAPPER \
      --replace /opt "${mfcj200lpr}/opt" \
      --replace /usr "${mfcj200lpr}/usr" \
      --replace /etc "$out/etc"

    substituteInPlace $WRAPPER \
      --replace "\`cp " "\`cp -p " \
      --replace "\`mv " "\`cp -p "

    #sed -i -e '110,261!d' $WRAPPER
    #substituteInPlace $WRAPPER \
    #  --replace "$``{device_model``}" "Printers" \
    #  --replace "$``{printer_model``}" "${model}" \
    #  --replace "/opt/brother/Printers/${model}/inf/br${model}rc" \
    #    "${mfcj200lpr}/opt/brother/Printers/${model}/inf/br${model}rc" \
    #  --replace "/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1" \
    #    "$out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1" \
    #  --replace "/usr/share/cups/model/Brother/brother_" \
    #    "$out/opt/brother/Printers/${model}/cupswrapper/brother_"
    wrapProgram $WRAPPER \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ coreutils gnused gnugrep ] }

    mkdir -p $out/lib/cups/filter
    mkdir -p $out/share/cups/model
    ln $out/opt/brother/Printers/${model}/cupswrapper/cupswrapper${model} $out/lib/cups/filter
    ln $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd  $out/share/cups/model

    patchelf --set-interpreter ${stdenv.glibc}/lib/ld-linux.so.2 \
      $out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1
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
